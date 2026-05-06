{ pkgs, ... }:

{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      auto-optimise-store = true;
      sandbox = true;
      accept-flake-config = false;
      experimental-features = [ "nix-command" "flakes" ];
      keep-outputs = true;
      keep-derivations = true;
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      http-connections = 50;
      connect-timeout = 30;
      fallback = true;
      min-free = 2147483648;
      max-free = 6442450944;
      trusted-users = [ "root" "@wheel" ];

      substituters = [
        "https://cache.aceclan.no"
        "https://cache.nixos.org"
        "https://attic.xuyh0120.win/lantian"
      ];

      trusted-substituters = [
        "https://cache.aceclan.no"
        "https://cache.nixos.org"
        "https://attic.xuyh0120.win/lantian"
      ];

      trusted-public-keys = [
        "cache.aceclan.no-1:qfGAXabgsofKSAqId9sqqbPlQic4l7gOGeWPrqUg3ak="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
    };

    gc = {
      automatic = true;
      dates = "Sun 04:30";
      options = "--delete-older-than 3d";
      # persistent=false: don't run a missed GC immediately at boot
      # (consumed 5.7G read I/O + 4.1G RAM, made desktop feel sluggish).
      persistent = false;
      randomizedDelaySec = "30min";
    };

    optimise.automatic = true;
  };

  # Run GC + store optimise at lowest CPU/I/O priority so they never
  # contend with foreground apps. Takes longer overall, doesn't stall
  # alacritty starts or anything else.
  systemd.services.nix-gc.serviceConfig = {
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    Nice = 19;
  };

  systemd.services.nix-optimise.serviceConfig = {
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    Nice = 19;
  };

  # Memory cap on nix builds via cgroup. Kernel throttles at MemoryHigh,
  # hard limit MemoryMax. Prevents OOM crashing desktop on 15G boxes.
  # Builds slow down or get killed instead of taking down system.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryHigh = "80%";
    MemoryMax = "90%";
    Delegate = "memory cpu io";
  };

  # fstrim: same reasoning — async at night, never replay at boot.
  services.fstrim = {
    interval = "Sun 04:00";
  };
  systemd.timers.fstrim.timerConfig.Persistent = false;
}

