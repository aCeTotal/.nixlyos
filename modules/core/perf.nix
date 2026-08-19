{ pkgs, ... }:

{
  # Performance tunings on top of linuxPackages_zen.

  # Single owner of the governor: power-profiles-daemon and gamemode's own
  # governor knobs are disabled elsewhere so this always wins.
  powerManagement.cpuFreqGovernor = "performance";

  # NVMe gets none for lowest latency; SATA gets bfq, which unlike mq-deadline
  # actually honours ioprio, so a Steam download no longer freezes the desktop.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="bfq"
  '';

  # systemd-oomd and the vm.dirty_* knobs live in zram.nix.

  # Raise open-file and memlock limits for game engines, electron and IDEs.
  # @audio gets rtprio so PipeWire never starves under compositor load, and
  # @gamemode gets rtprio plus nice because setpriority(-10) otherwise EACCESes.
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile";  value = "524288";    }
    { domain = "*"; type = "hard"; item = "nofile";  value = "1048576";   }
    { domain = "*"; type = "soft"; item = "memlock"; value = "unlimited"; }
    { domain = "*"; type = "hard"; item = "memlock"; value = "unlimited"; }
    { domain = "@audio"; type = "soft"; item = "rtprio"; value = "95"; }
    { domain = "@audio"; type = "hard"; item = "rtprio"; value = "95"; }
    { domain = "@gamemode"; type = "soft"; item = "rtprio"; value = "95"; }
    { domain = "@gamemode"; type = "hard"; item = "rtprio"; value = "95"; }
    { domain = "@gamemode"; type = "soft"; item = "nice"; value = "-20"; }
    { domain = "@gamemode"; type = "hard"; item = "nice"; value = "-20"; }
  ];

  boot.kernel.sysctl = {
    # Filesystem
    "fs.inotify.max_user_watches"   = 524288;
    "fs.inotify.max_user_instances" = 8192;
    "fs.file-max"                   = 2097152;
    "fs.aio-max-nr"                 = 1048576;

    # Skip split-lock detection; detection itself costs performance.
    "kernel.split_lock_mitigate" = 0;

    # No background compaction: kcompactd bursts show up as frame-time spikes,
    # and nixlytile's game mode compacts explicitly at game start.
    "vm.compaction_proactiveness" = 0;
    # Keep watermark boosting from kicking kswapd into aggressive reclaim.
    "vm.watermark_boost_factor" = 0;
  };
}
