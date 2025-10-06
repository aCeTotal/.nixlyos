{ config, lib, pkgs, ... }:

{
  boot.kernelModules = [ "tcp_bbr" ];

  boot.kernel.sysctl = {
    "net.core.rmem_default" = 4194304;
    "net.core.wmem_default" = 4194304;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 262144 134217728";
    "net.ipv4.tcp_wmem" = "4096 262144 134217728";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.somaxconn" = 4096;
    "net.core.netdev_max_backlog" = 250000;
    "net.ipv4.ip_local_port_range" = "10240 65535";
    "net.ipv4.tcp_ecn" = 1;
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    # Valid values: "true" | "resolve" | "false"
    llmnr = "false";
  };

  # Enable NetworkManager here instead, per request
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkDefault "systemd-resolved";

  # Start nm-applet as a user service (Hyprland-friendly)
  systemd.user.services = {
    nm-applet = {
      description = "Network manager applet";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      # Use --indicator so it shows up in Waybar's SNI tray
      serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
    };
  };

  # Avoid blocking boot on wait-online
  systemd.services.NetworkManager-wait-online.enable = false;
}
