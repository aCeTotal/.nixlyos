{ pkgs, lib, ... }:

{
  # File manager, integration, and helpers
  home.packages = (with pkgs; [
    # File manager + plugins
    thunar
    thunar-archive-plugin
    thunar-volman
    thunar-media-tags-plugin
    tumbler
    # Integration and utilities
    xfce4-exo
    desktop-file-utils
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
    # Fallback shim so exo's built-in fallback (xfce4-terminal) resolves to Alacritty
    (pkgs.writeShellScriptBin "xfce4-terminal" ''
      #!/usr/bin/env bash
      exec alacritty "$@"
    '')
  ];

  # Make Thunar's "Open Terminal Here" use Alacritty via exo
  # Provide a desktop entry with TerminalEmulator categories and TryExec for detection
  home.file.".local/share/applications/Alacritty.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Alacritty
    GenericName=Terminal
    Comment=Alacritty Terminal
    TryExec=alacritty
    Exec=alacritty
    Icon=Alacritty
    Categories=System;TerminalEmulator;
    X-XFCE-Category=TerminalEmulator
    StartupNotify=true
  '';

  # Provide an exo helper so exo-open can discover Alacritty
  home.file.".local/share/xfce4/helpers/Alacritty.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Alacritty
    Comment=Terminal Emulator
    Exec=alacritty
    TryExec=alacritty
    Icon=Alacritty
    NoDisplay=true
    X-XFCE-Category=TerminalEmulator
    X-XFCE-Commands=alacritty
    X-XFCE-CommandsWithParameter=alacritty --working-directory %s
    X-XFCE-Binaries=alacritty
    StartupNotify=true
  '';

  # Configure exo helpers. Some versions read Preferred Applications, others Helpers.
  home.file.".config/xfce4/helpers.rc".text = ''
    [Preferred Applications]
    TerminalEmulator=Alacritty
    XPreferredTerminal=Alacritty

    [Helpers]
    TerminalEmulator=Alacritty
  '';

  # Thunar custom action as a robust fallback (visible on directories)
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>Alacritty</icon>
        <name>Åpne terminal her (Alacritty)</name>
        <unique-id>alacritty-open-terminal-here</unique-id>
        <command>alacritty --working-directory %f</command>
        <description>Åpner Alacritty i denne mappen</description>
        <patterns>*</patterns>
        <startup-notify>false</startup-notify>
        <directories/>
      </action>
    </actions>
  '';

  # Keep desktop database current so DEs pick up entries
  home.activation.updateDesktopDatabase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$HOME/.local/share/applications" || true
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
