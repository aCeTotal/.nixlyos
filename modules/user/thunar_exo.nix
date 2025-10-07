{ pkgs, lib, ... }:

{
  # File manager, integration, and helpers
  home.packages = (with pkgs; [
    # File manager + plugins
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.thunar-media-tags-plugin
    xfce.tumbler
    # Integration and utilities
    xfce.exo
    gtkhash
    ffmpegthumbnailer
    poppler
    libgsf
    libopenraw
    p7zip
    zip
    unzip
    unrar
    file-roller
  ]) ++ [
    # Helper: open Thunar from terminal in current directory
    (pkgs.writeShellScriptBin "openthunar" ''
      #!/usr/bin/env bash
      set -euo pipefail
      target="''${1:-$PWD}"
      if [ -f "$target" ]; then
        target="$(dirname "$target")"
      fi
      if command -v thunar >/dev/null 2>&1; then
        nohup thunar "$target" >/dev/null 2>&1 &
      else
        nohup xdg-open "$target" >/dev/null 2>&1 &
      fi
    '')
  ];

  # Make Thunar's "Open Terminal Here" use Alacritty via exo
  xdg.configFile."xfce4/helpers.rc".text = ''
    [Preferred Applications]
    TerminalEmulator=alacritty
  '';

  # Set Thunar as default handler for directories
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
    "application/x-gnome-saved-search" = [ "thunar.desktop" ];
  };

  # Theme and icons (moved here as requested)
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 21;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-enable-tooltips" = 1;
      "gtk-tooltip-timeout" = 10;
      "gtk-tooltip-browse-timeout" = 10;
      "gtk-tooltip-browse-mode-timeout" = 10;
    };
    gtk4.extraConfig = {
      "gtk-enable-tooltips" = 1;
      "gtk-tooltip-timeout" = 10;
      "gtk-tooltip-browse-timeout" = 10;
      "gtk-tooltip-browse-mode-timeout" = 10;
    };
  };
}
