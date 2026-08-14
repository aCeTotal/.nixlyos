{ lib, ... }:

# Overhead-trimming: ting som kjørte kontinuerlig uten å levere løpende
# verdi. Hver enkelt post dokumenterer hva den erstatter.
{
  # OpenRGB-serveren lå resident (USB/i2c-håndtak åpne hele tiden) men
  # eneste bruker er nixly-input-hardware-oneshoten (input.nix, generert
  # av nixlycc), som kjører `openrgb --noautoconnect` STANDALONE og aldri
  # har snakket med serveren. RGB-moduset settes i firmware ved boot og
  # består. mkForce fordi input.nix er auto-generert med enable = true.
  services.hardware.openrgb.enable = lib.mkForce false;
  # openrgb-modulen dro inn i2c-dev; oneshoten trenger den fortsatt for
  # RAM/hovedkort-RGB via SMBus.
  boot.kernelModules = [ "i2c-dev" ];

  # NixOS-default kjører logrotate HVER TIME — journald har allerede
  # 200M-tak (system_services.nix), og ingenting annet roterer ofte.
  systemd.timers.logrotate.timerConfig.OnCalendar = lib.mkForce "daily";
}
