{ lib, pkgs-stable, pkgs-unstable, system, inputs, ... }:

let
  stablePackages = with pkgs-stable; [
    discord
    freecad
    brave
    firefox
    google-chrome
    gimp
    celluloid
    pureref
    teams-for-linux
    speedtree
    claude
    # Screenshot
    grim
    slurp
    wl-clipboard
    spotify
    mpv
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
