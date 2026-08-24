{ pkgs, ... }:

let
  # Cores, RAM and build parallelism for this machine, from scripts/detect-hw.sh.
  hw = import ./hw/resources.nix;
in
{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      # No auto-optimise-store: the weekly nix-optimise timer does the same job
      # without hardlinking synchronously during every build.
      sandbox = true;
      accept-flake-config = false;
      # detect-hw.sh writes generated files before each eval, so the tree is always dirty.
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];
      keep-outputs = true;
      keep-derivations = true;
      builders-use-substitutes = true;
      # Scaled to RAM and cores: one job per 8 GiB, capped by both.
      max-jobs = hw.maxJobs;
      cores = hw.buildCores;
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
        # Prebuilt CachyOS kernel + nvidia module; without this they build from source.
        "https://nyx-cache.chaotic.cx/"
      ];

      trusted-substituters = [
        "https://cache.aceclan.no"
        "https://cache.nixos.org"
        "https://attic.xuyh0120.win/lantian"
        "https://nyx-cache.chaotic.cx/"
      ];

      trusted-public-keys = [
        "cache.aceclan.no-1:qfGAXabgsofKSAqId9sqqbPlQic4l7gOGeWPrqUg3ak="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      ];
    };

    gc = {
      automatic = true;
      dates = "Sun 04:30";
      options = "--delete-older-than 3d";
      # No catch-up GC at boot; it cost gigabytes of read I/O and RAM.
      persistent = false;
      randomizedDelaySec = "30min";
    };

    optimise.automatic = true;
  };

  # GC and optimise run at idle priority so they never contend with foreground apps.
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

  # Cgroup memory cap so a runaway build is killed instead of the desktop.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryHigh = "80%";
    MemoryMax = "90%";
    Delegate = "memory cpu io";
  };

  # fstrim: same reasoning, async at night and never replayed at boot.
  services.fstrim = {
    interval = "Sun 04:00";
  };
  systemd.timers.fstrim.timerConfig.Persistent = false;
}

