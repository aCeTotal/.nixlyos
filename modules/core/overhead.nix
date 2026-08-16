{ lib, ... }:

{
  services.hardware.openrgb.enable = lib.mkForce false;
  boot.kernelModules = [ "i2c-dev" ];

  systemd.timers.logrotate.timerConfig.OnCalendar = lib.mkForce "daily";
}
