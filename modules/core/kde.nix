{ config, lib, pkgs, ... }:

# KDE Plasma 6 (siste utgave fra nixos-unstable). Pakker + session.
# Tiling/gaps konfig ligger i kde_config.nix.

{
  imports = [ ./kde_config.nix ];

  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";
  services.xserver.enable = false;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-nm
    elisa
    khelpcenter
    kate
    oxygen
  ];

  environment.systemPackages = with pkgs; [
    polonium
    kdePackages.kwin
    kdePackages.plasma-workspace
    kdePackages.qtwayland
    wl-clipboard
    libnotify
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    KWIN_DRM_ALLOW_NVIDIA_COLORSPACE_HDR = "1";
  };
}
