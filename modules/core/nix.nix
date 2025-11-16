{ lib, pkgs, ... }:

{
  # Allow unfree packages for system-level nixpkgs (e.g., NVIDIA, CUDA, etc.).
  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      # Prefer binary caches to avoid local source builds
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixlyos.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf/f+mU9ZfZPmEH9JPE0RSeW8V1w0x9Wl6iY="
        "nixlyos.cachix.org-1:MHb4zMKxhNmxw/aHmRVBJj3gjEp0VJphEfO8zAa+yWM="
      ];
      experimental-features = [ "nix-command" "flakes" "cgroups" "auto-allocate-uids" ];
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      builders-use-substitutes = true;
      max-jobs = 1;
      cores = 6;
      http-connections = 50;
      connect-timeout = 30;
      fallback = true;
      min-free = 2147483648;
      max-free = 6442450944;
      trusted-users = [ "root" "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise.automatic = true;
  };
}
