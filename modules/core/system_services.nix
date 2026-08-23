{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gcr        # Secret agent and password prompting
    libsecret  # Secret Service D-Bus interface
    iotop
    htop
    btop
  ];

  programs.neovim.defaultEditor = true;

  # No cpuFreqGovernor here: perf.nix owns it.

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    # Default ssh-agent instead, to avoid a conflict.
    enableSSHSupport = false;
  };
  programs.dconf.enable = true;

  security.rtkit.enable = true;
  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.fstrim.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Auto-unlock GNOME Keyring via PAM for sddm, ly and TTY login.
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Confine every IRQ to core 0's SMT threads so they never preempt a game frame.
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

      # thread_siblings_list is either "0,8" or "0-1".
      allowed=""
      IFS=, read -ra parts <<< "$sibs"
      for p in "''${parts[@]}"; do
        case "$p" in
          *-*) for ((c=''${p%-*}; c<=''${p#*-}; c++)); do allowed="$allowed $c"; done ;;
          *)   allowed="$allowed $p" ;;
        esac
      done

      # Hex mask of the disallowed CPUs, 32-bit groups, most significant first.
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

  # Latency-aware virtual deadline CPU scheduler.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # Early OOM killer, backing up systemd-oomd.
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 5;       # Kill when <5% RAM free
    freeSwapThreshold = 10;     # Kill when <10% swap free
    # earlyoom matches on comm (15 chars), so "chrome" not "google-chrome-stable".
    extraArgs = [
      "--prefer" "^(Web Content|firefox|chrome|chromium|electron)$"
      "--avoid" "^(sshd|systemd|dbus)$"
    ];
  };

  boot.kernel.sysctl = {
    # The sched_*_granularity_ns knobs are gone; EEVDF replaced CFS in the zen kernel.
    "kernel.sched_autogroup_enabled" = 1;

    # watermark_boost_factor and compaction_proactiveness live in perf.nix.
    "vm.watermark_scale_factor" = 125;  # More aggressive reclaim
    "vm.zone_reclaim_mode" = 0;         # Zone reclaim off, lower latency
    "vm.stat_interval" = 10;            # Less frequent vm stats
  };

  # Faster boot and shutdown.
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultDeviceTimeoutSec = "10s";
  };

  # Cap the journal; it grew past 500 MB unbounded.
  services.journald.extraConfig = ''
    SystemMaxUse=200M
  '';
}
