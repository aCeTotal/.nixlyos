{ pkgs, lib, config, ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      randomizedDelaySec = "14m";
      options = "--delete-older-than 30d";
    };
    settings =
      {
      max-jobs = "auto";
      cores = 0;
      sandbox = true;
      keep-going = true;
      restrict-eval = false;
      accept-flake-config = false;
      allow-import-from-derivation = true;
      builders-use-substitutes = true;
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      
      fallback = true;
      allowed-users = [ "total" ];

      min-free = 2147483648;   # 2 GiB
      max-free = 6442450944;   # 6 GiB

      substituters = [
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      };
  };

    environment.systemPackages = [pkgs.cachix];
}
