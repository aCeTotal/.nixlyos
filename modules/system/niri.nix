{ pkgs, lib, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.portal = {
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.niri.default = lib.mkForce [ "gtk" "wlr" ];
  };

  systemd.suppressedSystemUnits = [
    "systemd-backlight@backlight:intel_backlight.service"
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
  };

  services.displayManager.defaultSession = "niri";

  services.xserver.enable = true;

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
