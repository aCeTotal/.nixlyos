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
    libreoffice-fresh
    codex
    (blender.override { cudaSupport = true; })
    speedtree
    nixlytile
    spotify
    mpv
    vlc
      bottles
      steam-run
      anime-downloader
      lutris
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
