{ pkgs, pkgs-hyprland, ... }:

{
# HYPRLAND — version pinned at 0.54.3 via nixpkgs-hyprland flake input
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs-hyprland.hyprland;
    portalPackage = pkgs-hyprland.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
# If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
# Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  services.displayManager.defaultSession = "hyprland";

  services.xserver.enable = true;

}
