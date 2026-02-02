{ pkgs, ... }:

{
  # Gnome keyring secret agent for NetworkManager VPN passwords
  systemd.user.services.gnome-keyring-secrets = {
    description = "GNOME Keyring secrets component";
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets";
      Restart = "on-failure";
    };
  };

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
  powerManagement.cpuFreqGovernor = "powersave";

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

  # Auto-unlock GNOME Keyring via PAM for ly (DM) and TTY login
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # ========================================
  # ANANICY-CPP - Auto Nice Daemon for better responsiveness
  # ========================================
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    settings = {
      check_freq = 1000;        # Check processes every 1s
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
  # IRQBALANCE - Distribute IRQs across CPUs for better performance
  # ========================================
  services.irqbalance.enable = true;

  # ========================================
  # EARLYOOM - Early OOM killer (backup to systemd-oomd)
  # ========================================
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 5;       # Kill when <5% RAM free
    freeSwapThreshold = 10;     # Kill when <10% swap free
    extraArgs = [
      "--prefer" "^(Web Content|firefox|chromium|electron)$"
      "--avoid" "^(sshd|systemd|dbus)$"
    ];
  };

  # ========================================
  # KERNEL SYSCTL FOR RESPONSIVENESS
  # ========================================
  boot.kernel.sysctl = {
    # Reduce latency - important for gaming and responsiveness
    "kernel.sched_min_granularity_ns" = 500000;   # 0.5ms min scheduling granularity
    "kernel.sched_wakeup_granularity_ns" = 250000; # 0.25ms wakeup granularity
    "kernel.sched_migration_cost_ns" = 250000;    # Reduce migration cost
    "kernel.sched_nr_migrate" = 128;              # Migrate more tasks at once
    "kernel.sched_autogroup_enabled" = 1;         # Group processes for fairness

    # Memory management for responsiveness
    "vm.watermark_boost_factor" = 0;    # Disable watermark boosting
    "vm.watermark_scale_factor" = 125;  # More aggressive reclaim
    "vm.compaction_proactiveness" = 0;  # Disable proactive compaction (reduces stutter)
    "vm.zone_reclaim_mode" = 0;         # Disable zone reclaim (reduces latency)
    "vm.stat_interval" = 10;            # Less frequent vm stats (reduces overhead)

    # Improve I/O responsiveness
    "kernel.io_delay_type" = 0;         # Udelay (faster but uses CPU)

    # Hugepages for gaming
    "vm.nr_hugepages" = 512;            # Pre-allocate 1GB of 2MB hugepages
  };

  # ========================================
  # SYSTEMD OPTIMIZATIONS - Faster boot/shutdown
  # ========================================
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultDeviceTimeoutSec = "10s";
  };
}
