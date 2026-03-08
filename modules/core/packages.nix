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
    codex
    (blender.override { cudaSupport = true; })
    speedtree
    claude
    nixlytile
    # Screenshot
    grim
    slurp
    wl-clipboard
    citrix-workspace-nixly
    spotify
    mpv
    vlc
    onlyoffice-desktopeditors
    pavucontrol
  ];

  unstablePackages = with pkgs-unstable; [
  ];
in
{
  config.home-manager.sharedModules = [
    {
      home.packages = stablePackages ++ unstablePackages;
    }
  ];
}
