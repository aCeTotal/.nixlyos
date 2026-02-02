{ config, lib, pkgs, ... }:

{
  # Kernel-moduler for nettverk og VPN
  boot.kernelModules = [
    "tcp_bbr"
    # IPsec/IKEv2
    "af_key"
    "ah4"
    "ah6"
    "esp4"
    "esp6"
    "xfrm_user"
    "xfrm_algo"
    # L2TP
    "l2tp_core"
    "l2tp_netlink"
    "l2tp_ppp"
    # PPTP
    "nf_conntrack_pptp"
    "nf_nat_pptp"
    # TUN/TAP for OpenVPN
    "tun"
    # WireGuard (innebygd i moderne kernels)
    "wireguard"
  ];

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
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      LLMNR = "no";
    };
  };

  # Enable NetworkManager here instead, per request
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkDefault "systemd-resolved";

  # NetworkManager VPN plugins
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn      # OpenVPN
    networkmanager-vpnc         # Cisco VPN
    networkmanager-openconnect  # Cisco AnyConnect / OpenConnect
    networkmanager-fortisslvpn  # Fortinet SSL VPN
    networkmanager-l2tp         # L2TP/IPsec
    networkmanager-sstp         # SSTP (Microsoft)
  ];

  systemd.services.NetworkManager-wait-online.enable = false;

  # StrongSwan for IKEv2/IPsec
  services.strongswan = {
    enable = true;
    secrets = [ "/etc/ipsec.secrets" ];
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    kdePackages.plasma-nm

    # VPN-klienter
    openvpn
    wireguard-tools
    openconnect              # Cisco AnyConnect-kompatibel
    vpnc                     # Cisco VPN
    sstp-client              # SSTP-klient
    strongswan               # IKEv2/IPsec
    libreswan                # Alternativ IPsec
    openfortivpn             # Fortinet

    # Nyttige verktøy
    iproute2
    iptables
    nftables
  ];
}
