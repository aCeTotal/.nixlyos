{ config, lib, pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      # Set default theme to Gruvbox Dark
      color_theme = "gruvbox_dark";
    };
  };
}

