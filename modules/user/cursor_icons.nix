{ lib, pkgs, ... }:

{

    home.pointerCursor = {
      gtk.enable = true;
      # x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 21;
    };

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        # Adwaita is generally bundled; this keeps it explicit
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      # Keep only extra config; leave the theme/icons/fonts to GTK defaults
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
