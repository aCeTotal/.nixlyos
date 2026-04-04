{ config, lib, pkgs, ... }:

{
    services.desktopManager.plasma6.enable = true;

    # Ekskluder tunge KDE-pakker som drar inn qtwebengine
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-nm
    ];
}
