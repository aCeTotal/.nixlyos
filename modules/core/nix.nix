{ lib, pkgs, ... }:

{
  # Allow unfree packages for system-level nixpkgs (e.g., NVIDIA, CUDA, etc.).
  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      experimental-features = [ "nix-command" "flakes" "cgroups" "auto-allocate-uids" ];
      auto-optimise-store = true;
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
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise.automatic = true;
  };
}
