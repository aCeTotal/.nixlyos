{ pkgs, ... }:

{
  # Performance tunings on top of linuxPackages_cachyos.

  # Single owner of the governor: power-profiles-daemon and gamemode's own
  # governor knobs are disabled elsewhere so this always wins.
  powerManagement.cpuFreqGovernor = "performance";

  # Demote background work (nix builds, indexers, updaters) to SCHED_IDLE/
  # low nice via the CachyOS rule set. Complements gamemode, which only
  # boosts the game itself. Touches nice/ionice only, never CPU affinity,
  # so it cannot race nixlytile.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    # The CachyOS "Game" type is nice -5; on titles in its list that reset
    # gamemode's renice (-10) within 15 s. Redefine the type to match so
    # the two agree instead of fighting.
    extraTypes = [
      { type = "Game"; nice = -10; ioclass = "best-effort"; ionice = 0; }
    ];
  };

  # MGLRU: keep the last second of the working set out of reclaim so memory
  # pressure refaults game pages less. Earlier OOM under pressure is fine:
  # earlyoom plus the -900 oom_score_adj game tree handle that.
  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000"
  ];

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
    # Upstream default 5 lets page-lock holders re-steal the lock; long waiter
    # stalls show as stutter during asset streaming. CachyOS ships 1.
    "vm.page_lock_unfairness" = 1;
  };
}
