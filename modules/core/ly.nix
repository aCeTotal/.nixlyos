{ pkgs, pkgs-stable, ... }:

{

  services.displayManager.ly.enable = true;

  services.displayManager.sessionPackages = [
    pkgs-stable.nixlytile

  ];

}
