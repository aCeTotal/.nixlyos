{ pkgs, ... }:

{
  # Live Android screen mirroring via scrcpy, with mouse and keyboard control.
  # Needs USB debugging enabled on the phone; `adb tcpip 5555` moves it to wifi.

  # No programs.adb needed: systemd grants uaccess on the USB device itself.
  environment.systemPackages = with pkgs; [
    scrcpy
    android-tools # adb
  ];
}
