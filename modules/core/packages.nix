{ lib, pkgs-stable, ... }:

let
  hmStablePkgs = with pkgs-stable; [
    discord
    gimp
    celluloid
    google-chrome
    pureref
    teams-for-linux
    libreoffice-fresh
    codex
    (blender.override { cudaSupport = true; })
  ];
in {
  config = {
    home-manager.sharedModules = [
      { home.packages = hmStablePkgs; }
    ];
  };
}

