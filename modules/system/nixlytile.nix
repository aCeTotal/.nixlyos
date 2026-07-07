{ pkgs, lib, ... }:

{
  services.displayManager.sessionPackages = [ pkgs.nixlytile ];
  services.displayManager.defaultSession = "nixlytile";

  environment.systemPackages = [ pkgs.nixlytile ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-wlr ];
    config.nixlytile.default = lib.mkForce [ "wlr" "gtk" ];
  };

  systemd.suppressedSystemUnits = [
    "systemd-backlight@backlight:intel_backlight.service"
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "nixlytile";
    XDG_SESSION_DESKTOP = "nixlytile";
  };

  # services.xserver.enable fjernet: Wayland-only session (SDDM kjører
  # wayland, X11-apper går via xwayland-satellite) — full Xorg-stack
  # var ren closure/boot-bloat som ingenting startet.
  security.polkit.enable = true;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
