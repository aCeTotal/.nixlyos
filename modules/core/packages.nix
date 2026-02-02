{ lib, pkgs-stable, system, inputs, ... }:

let
  hmPackages = with pkgs-stable; [
    discord
    freecad
    claude-code
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
    nixlytile
    spotify
    mpv
    vlc
    onlyoffice-desktopeditors
  ];
in
{
  config.home-manager.sharedModules = [
    {
      home.packages = hmPackages;
    }
  ];
}
