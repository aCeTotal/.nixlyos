{ pkgs, ... }:

{
  # Performance tunings on top of linuxPackages_zen.
  # Kernel & sysctl already covered: ananicy-cpp + cachyos rules, scx_lavd,
  # earlyoom, irqbalance, zram, BBR+fq, gamemode, btrfs noatime+zstd+ssd.

  # CPU-governor: performance, alltid, paa alle maskiner. Én eier — derfor er
  # power-profiles-daemon slaatt av (cpu/intel.nix, cpu/amd.nix) og
  # desiredgov/defaultgov fjernet fra feral gamemode (gaming.nix). Med
  # intel_pstate=active / amd_pstate=active betyr dette EPP=performance, dvs.
  # maks turbo-residency ogsaa utenfor spill (menyer, shader-kompilering,
  # kompilering). Kostnad: hoeyere idle-forbruk/varme paa laptop.
  powerManagement.cpuFreqGovernor = "performance";

  # Per-device IO scheduler: NVMe→none (ingen kø-omorganisering = lavest
  # latency; NVMe har dyp hardware-kø og trenger ingen fairness-scheduler),
  # SATA SSD/HDD→bfq. mq-deadline paa SATA-SSD ignorerer io-prioriteter:
  # Steams idle-ioprio paa shader-kompilering og ananicys "ioclass idle"
  # hadde null effekt, saa en stor Steam-oppdatering la desktopens
  # page-fault-lesinger bakerst i samme kø — maskinen frøs i sekundvis
  # under nedlasting. BFQ haandhever ioprio + per-prosess-fairness.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="bfq"
  '';

  # systemd-oomd already enabled in zram.nix; vm.dirty_*, vfs_cache_pressure
  # and min_free_kbytes also defined there.

  # Raise open-file + memlock limits for game engines, electron, IDEs.
  # rtprio for @audio: lets PipeWire/mpv audio threads take RT scheduling
  # directly via RLIMIT_RTPRIO (no rtkit round-trip needed) so audio never
  # starves under GPU-composite/compositor load — the occasional playback
  # audio dropouts on the HTPC.
  #
  # @gamemode faar rtprio + nice: uten RLIMIT_NICE staar gulvet paa 0, og
  # nixlytile sin `setpriority(game, -10)` feilet med EACCES — hele
  # prioriterings-halvdelen av game mode var en no-op. rtprio 95 her (ikke
  # bare via @audio) saa compositor-RT-boosten virker paa maskiner der
  # brukeren ikke er i audio-gruppa.
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

    # Skip split-lock detection (CachyOS default — perf cost on detection)
    "kernel.split_lock_mitigate" = 0;

    # No background memory compaction during gameplay — kcompactd bursts
    # show up as frame-time spikes. nixlytile's game mode triggers an
    # explicit compaction at game start, which covers the THP need.
    "vm.compaction_proactiveness" = 0;
    # Don't let watermark boosting kick kswapd into aggressive reclaim on
    # fragmentation (another background stutter source under memory load).
    "vm.watermark_boost_factor" = 0;
  };
}
