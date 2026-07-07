{ config, pkgs, lib, ... }:

{
  time.timeZone = "Europe/Oslo";
  # hardwareClockInLocalTime=true skrur av kjernens RTC-tilbakeskriving
  # (11-minute mode).  Med død CMOS-batteri starter hver boot i 2019 og
  # tidshoppet til nå får alle OnCalendar-timere (nix-gc, fstrim, ...)
  # til å fyre umiddelbart ved boot — minutter med IO-storm.  UTC-RTC
  # lar kjernen holde klokka synket.  (Gjelder kun uten Windows dual-boot.)
  time.hardwareClockInLocalTime = false;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "nb_NO.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
    LC_TIME = "nb_NO.UTF-8";
  };

  console = {
    packages = [ pkgs.terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-i22b.psf.gz";
    keyMap = "no";
  };

  services.libinput.enable = true;
  services.xserver.xkb = {
    layout = "no";
  };

  services.timesyncd.enable = true;
}

