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
    # Socket buffer sizes (auto-tuned within these caps).
    "net.core.rmem_default" = 4194304;
    "net.core.wmem_default" = 4194304;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 262144 134217728";
    "net.ipv4.tcp_wmem" = "4096 262144 134217728";
    "net.core.optmem_max" = 65536;

    # BBR + cake → minst bufferbloat, høyest gjennomstrømming.
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # TCP path/feature tuning.
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_fastopen" = 3;          # client + server TFO
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_dsack" = 1;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_timestamps" = 1;

    # Send-side bufferbloat-cap (lavere latency for HTTP/2/3, gaming).
    "net.ipv4.tcp_notsent_lowat" = 131072;
    # Behold cwnd mellom keep-alive idle perioder → raskere gjenopptak.
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Død-connection deteksjon: 60 s idle, 10 s probe-interval, 6 probes.
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;

    # Connection churn (browser parallel-fetch, mange korte connections).
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_fin_timeout" = 10;
    "net.ipv4.tcp_max_syn_backlog" = 8192;

    # Listen-backlog + RX queue for høy throughput.
    "net.core.somaxconn" = 4096;
    "net.core.netdev_max_backlog" = 250000;
    "net.core.netdev_budget" = 600;
    "net.core.netdev_budget_usecs" = 8000;

    # Lokal port-pool — masse plass til parallelle HTTP-connections.
    "net.ipv4.ip_local_port_range" = "10240 65535";

    # Lav-latency NIC busy-poll for gaming + tale (μs).
    "net.core.busy_poll" = 50;
    "net.core.busy_read" = 50;

    # UDP-buffer minima — bedre QUIC/HTTP3 og spilltrafikk.
    "net.ipv4.udp_rmem_min" = 16384;
    "net.ipv4.udp_wmem_min" = 16384;

    # Receive Packet Steering: spred RX over CPU-kjerner.
    "net.core.rps_sock_flow_entries" = 32768;
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "1.1.1.1#cloudflare-dns.com"
        "1.0.0.1#cloudflare-dns.com"
        "9.9.9.9#dns.quad9.net"
      ];
      LLMNR = "false";
    };
  };

  # Enable NetworkManager here instead, per request
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkDefault "systemd-resolved";
  networking.networkmanager.wifi.powersave = false;

  # Stabil MAC: random MAC kan trigge AP/DHCP å kaste klienten.
  networking.networkmanager.wifi.scanRandMacAddress = false;
  networking.networkmanager.wifi.macAddress = "permanent";
  networking.networkmanager.ethernet.macAddress = "permanent";

  # IPv6 privacy extensions av (stabil adresse, færre rotasjoner).
  networking.tempAddresses = "disabled";

  # iwlwifi (Intel AX210) firmware-krasj fix:
  # NMI_INTERRUPT_HOST på 6 GHz/Wi-Fi 6E → SW-reset → mister forbindelse.
  # bt_coex_active=N: BT/WiFi antenne-coex av. power_save=0: ingen radio-sleep.
  # 11n_disable=8: AMSDU-aggregation av. disable_11ax=1: ingen Wi-Fi 6/6E (faller til 11ac).
  # power_scheme=1: iwlmvm full ytelse.
  boot.extraModprobeConfig = ''
    options iwlwifi bt_coex_active=N power_save=0 11n_disable=8 disable_11ax=1
    options iwlmvm power_scheme=1
  '';

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

  # Sprer NIC-IRQer over alle CPU-kjerner → jevnere latency under last.
  services.irqbalance.enable = true;

  # StrongSwan for IKEv2/IPsec
  services.strongswan = {
    enable = true;
    secrets = [ "/etc/ipsec.secrets" ];
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet

    # VPN-klienter
    openvpn
    wireguard-tools
    openconnect              # Cisco AnyConnect-kompatibel
    vpnc                     # Cisco VPN
    sstp                     # SSTP-klient
    strongswan               # IKEv2/IPsec
    libreswan                # Alternativ IPsec
    openfortivpn             # Fortinet

    # Nyttige verktøy
    iproute2
    iptables
    nftables
  ];
}
