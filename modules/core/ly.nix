{ pkgs, pkgs-stable, lib, ... }:

let
  opts = import ./nixlytile_options.nix;
  isHtpc = opts.nixlytileMode == 2;
in
{

  services.displayManager.ly.enable = true;

  services.displayManager.sessionPackages = [
  ];

  # Auto-login when HTPC mode is active (nixlytile_options.nix nixlytileMode = 2)
  services.displayManager.autoLogin = lib.mkIf isHtpc {
    enable = true;
    user = "total";
  };

}
