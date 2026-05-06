{ pkgs, ... }:

{
  # CachyOS-style performance tunings layered on linux-zen.
  # Kernel & sysctl already covered: ananicy-cpp + cachyos rules, scx_lavd,
  # earlyoom, irqbalance, zram, BBR+fq, gamemode, btrfs noatime+zstd+ssd.

  # Per-device IO scheduler: NVMe→kyber (CachyOS default; better mixed
  # read/write fairness than `none` for game-load patterns), SSD→mq-deadline,
  # HDD→bfq.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="kyber"
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  # systemd-oomd already enabled in zram.nix; vm.dirty_*, vfs_cache_pressure
  # and min_free_kbytes also defined there.

  # Raise open-file + memlock limits for game engines, electron, IDEs.
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile";  value = "524288";    }
    { domain = "*"; type = "hard"; item = "nofile";  value = "1048576";   }
    { domain = "*"; type = "soft"; item = "memlock"; value = "unlimited"; }
    { domain = "*"; type = "hard"; item = "memlock"; value = "unlimited"; }
  ];

  boot.kernel.sysctl = {
    # Filesystem
    "fs.inotify.max_user_watches"   = 524288;
    "fs.inotify.max_user_instances" = 8192;
    "fs.file-max"                   = 2097152;
    "fs.aio-max-nr"                 = 1048576;

    # Skip split-lock detection (CachyOS default — perf cost on detection)
    "kernel.split_lock_mitigate" = 0;
  };
}
