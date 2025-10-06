{ config, lib, pkgs, ... }:

{
  # Docker daemon + housekeeping
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = false;
      dates = "weekly";
    };
  };

  # Ensure user "total" can access Docker daemon
  users.users.total.extraGroups = lib.mkAfter [ "docker" ];

  # Kernel/network/storage modules commonly needed for Docker
  boot.kernelModules = lib.mkAfter [
    "ip_tables"
    "iptable_nat"
    "nf_nat"
    "br_netfilter"
    "overlay"
  ];

  # Userspace tools
  environment.systemPackages = lib.mkAfter (with pkgs; [ iptables ]);
}

