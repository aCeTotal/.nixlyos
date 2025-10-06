{ config, pkgs, lib, ... }:

{
  users.mutableUsers = true;

  users.users.total = {
    isNormalUser = true;
    description = "Primary user";
    home = "/home/total";
    shell = pkgs.bashInteractive;
    initialPassword = "nixly";
    extraGroups = [
      "wheel"
      "networkmanager"
      "bluetooth"
      "disk"
      "power"
      "video"
      "audio"
      "render"
      "systemd-journal"
      "dialout"
      "libvirtd"
      "kvm"
      "input"
      "uinput"
    ];
    openssh.authorizedKeys.keys = [];
  };

  users.groups.uinput = {};
}
