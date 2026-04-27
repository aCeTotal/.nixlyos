{ lib, pkgs-stable, pkgs-unstable, system, inputs, ... }:

let
  stablePackages = with pkgs-stable; [
    discord
    brave
    firefox
    google-chrome
    gimp
    celluloid
    pureref
    speedtree
    claude
    spotify
    vlc
    onlyoffice-desktopeditors
    pavucontrol
  ];

  unstablePackages = with pkgs-unstable; [
  (blender_nixly.override { cudaSupport = true; })
  ];
in
{
  config.home-manager.sharedModules = [
    {
      home.packages = stablePackages ++ unstablePackages;
    }
  ];
}
