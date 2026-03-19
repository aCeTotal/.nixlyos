{ pkgs, pkgs-unstable, ... }:

{

  services.displayManager.ly.enable = true;

  services.displayManager.sessionPackages = [
    pkgs-unstable.nixlytile

  ];

}
