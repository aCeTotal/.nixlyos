{ pkgs, ... }:

{
  # Packages needed for secret agent functionality
  environment.systemPackages = with pkgs; [
    gcr        # Secret agent and password prompting
    libsecret  # Secret Service D-Bus interface
    iotop      # I/O monitoring
    htop       # Process monitoring
    btop       # Modern resource monitor
  ];

  programs.neovim.defaultEditor = true;

  # Power Management
  # Ingen cpuFreqGovernor her: perf.nix eier den (performance, alltid).
  # Merk at *_pstate=active kun tilbyr performance/powersave — "schedutil"
  # fikk cpufreq.service til å feile ved hver boot.

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    # Use the default ssh-agent for stability; avoid conflict
    enableSSHSupport = false;
  };
  programs.dconf.enable = true;

  security.rtkit.enable = true;
  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.fstrim.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Auto-unlock GNOME Keyring via PAM for sddm (DM), ly og TTY login
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # ========================================
  # ANANICY-CPP - Auto Nice Daemon for better responsiveness
  # ========================================
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    # cachyos-reglene setter sddm/sddm-helper til BG_CPUIO (nice 16,
    # sched idle). SCHED_IDLE arves ved fork, saa hele den grafiske
    # sesjonen (compositor-barn, Steam, alle spill) endte i SCHED_IDLE —
    # spill fikk bare CPU naar ingen andre ville ha den. Fjern regelfila
    # saa sddm beholder normal SCHED_OTHER.
    rulesProvider = pkgs.runCommand "ananicy-rules-cachyos-no-sddm" { } ''
      cp -r ${pkgs.ananicy-rules-cachyos} $out
      chmod -R u+w $out
      rm $out/etc/ananicy.d/00-default/DEs-and-WMs/sddm.rules
    '';
    settings = {
      check_freq = 15;          # Full rescan every 15s (unit is SECONDS,
                                # not ms — 1000 meant every ~16.7 min).
                                # New processes still caught via proc events;
                                # 5s rescan was steady background CPU.
      cgroup_load = true;       # Use cgroups for better control
      type_load = true;         # Load type rules
      rule_load = true;         # Load process rules
      apply_latnice = true;     # Apply latency nice (EEVDF scheduler)
      apply_nice = true;        # Apply nice values
      apply_ioclass = true;     # Apply I/O scheduling class
      apply_ionice = true;      # Apply I/O priority
      apply_sched = true;       # Apply CPU scheduling policy
      apply_oom_score_adj = true; # Apply OOM score adjustments
      apply_cgroup = true;      # Apply cgroup rules
    };
  };

  # ========================================
  # IRQBALANCE - Hold avbrudd unna spillkjernene
  # ========================================
  # Default-irqbalance sprer IRQ-er over alle kjerner, inkludert dem spillet
  # kjoerer paa — hver NVMe-/nettverks-IRQ blir en preemption midt i en frame.
  # IRQBALANCE_BANNED_CPUS gjoer det motsatte: alle IRQ-er samles paa SMT-
  # traadene til fysisk kjerne 0, som er nettopp kjernen nixlytile reserverer
  # til compositoren. Statisk maske => ingen kamp mot runtime-pinning (den
  # gamle nixlytile-koden skrev smp_affinity, og irqbalance skrev over hvert
  # 10. sekund).
  #
  # Masken regnes ut ved oppstart fra faktisk topologi, saa den er riktig paa
  # alle maskiner: <8 logiske CPUer => ingen banning (for faa kjerner til aa
  # avse én).
  services.irqbalance.enable = true;
  systemd.services.irqbalance.serviceConfig.ExecStart = [
    ""
    (pkgs.writeShellScript "irqbalance-isolated" ''
      set -u
      ncpu=$(${pkgs.coreutils}/bin/getconf _NPROCESSORS_ONLN)
      sibs=$(${pkgs.coreutils}/bin/cat \
        /sys/devices/system/cpu/cpu0/topology/thread_siblings_list 2>/dev/null || echo 0)

      if [ "$ncpu" -lt 8 ]; then
        exec ${pkgs.irqbalance}/bin/irqbalance --foreground
      fi

      # thread_siblings_list er enten "0,8" (Intel/AMD SMT) eller "0-1".
      allowed=""
      IFS=, read -ra parts <<< "$sibs"
      for p in "''${parts[@]}"; do
        case "$p" in
          *-*) for ((c=''${p%-*}; c<=''${p#*-}; c++)); do allowed="$allowed $c"; done ;;
          *)   allowed="$allowed $p" ;;
        esac
      done

      # Bygg hex-maske over alle CPUer som IKKE er lov, 32-bits grupper,
      # mest signifikante gruppe foerst (irqbalance-formatet).
      ngroups=$(( (ncpu + 31) / 32 ))
      declare -a grp
      for ((i=0; i<ngroups; i++)); do grp[i]=0; done
      for ((c=0; c<ncpu; c++)); do
        case " $allowed " in *" $c "*) continue ;; esac
        gi=$((c / 32)); bit=$((c % 32))
        grp[gi]=$(( ''${grp[gi]} | (1 << bit) ))
      done
      mask=""
      for ((i=ngroups-1; i>=0; i--)); do
        printf -v h "%08x" "''${grp[i]}"
        if [ -z "$mask" ]; then mask="$h"; else mask="$mask,$h"; fi
      done

      export IRQBALANCE_BANNED_CPUS="$mask"
      echo "irqbalance: IRQ-er begrenset til CPU(er) $allowed (banned=$mask)"
      exec ${pkgs.irqbalance}/bin/irqbalance --foreground
    '')
  ];

  # ========================================
  # SCX LAVD - Latency-Aware Virtual Deadline CPU Scheduler
  # ========================================
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # ========================================
  # EARLYOOM - Early OOM killer (backup to systemd-oomd)
  # ========================================
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 5;       # Kill when <5% RAM free
    freeSwapThreshold = 10;     # Kill when <10% swap free
    # earlyoom matcher paa comm (15 tegn): "chrome" dekker google-chrome-
    # stable-prosessene som faktisk kjoerer her — gamle lista traff aldri.
    extraArgs = [
      "--prefer" "^(Web Content|firefox|chrome|chromium|electron)$"
      "--avoid" "^(sshd|systemd|dbus)$"
    ];
  };

  # ========================================
  # KERNEL SYSCTL FOR RESPONSIVENESS
  # ========================================
  boot.kernel.sysctl = {
    # Note: sched_min_granularity_ns, sched_wakeup_granularity_ns,
    # sched_migration_cost_ns, sched_nr_migrate do not exist in the
    # zen kernel (EEVDF scheduler replaced CFS).
    "kernel.sched_autogroup_enabled" = 1;         # Group processes for fairness

    # Memory management for responsiveness
    # (watermark_boost_factor + compaction_proactiveness settes i perf.nix)
    "vm.watermark_scale_factor" = 125;  # More aggressive reclaim
    "vm.zone_reclaim_mode" = 0;         # Disable zone reclaim (reduces latency)
    "vm.stat_interval" = 10;            # Less frequent vm stats (reduces overhead)

    # kernel.io_delay_type fjernet: styrer legacy ISA port-0x80-delay,
    # irrelevant på moderne hardware — bare sysctl-støy.
  };

  # ========================================
  # SYSTEMD OPTIMIZATIONS - Faster boot/shutdown
  # ========================================
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultDeviceTimeoutSec = "10s";
  };

  # Journal-tak: journalen lå på 500+ MB på /var/log uten grense.
  services.journald.extraConfig = ''
    SystemMaxUse=200M
  '';
}
