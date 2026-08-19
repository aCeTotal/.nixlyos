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

  # No services.xserver.enable: Wayland-only session, so the full Xorg stack was
  # closure and boot bloat that nothing started.
  security.polkit.enable = true;

  # The compositor starts this at login, but only if the unit file is in
  # /etc/systemd/user; without it graphical-session.target never activates.
  systemd.user.targets.nixlytile-session = {
    description = "nixlytile compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

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
