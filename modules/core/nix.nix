{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

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
      max-jobs = 3;
      cores = 6;
      http-connections = 50;
      connect-timeout = 30;
      fallback = true;
      min-free = 2147483648;
      max-free = 6442450944;
      trusted-users = [ "root" "@wheel" ];

      substituters = [
        "https://cache.nixos.org"
      ];

      trusted-substituters = [
        "https://cache.nixos.org"
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise.automatic = true;
  };
}

