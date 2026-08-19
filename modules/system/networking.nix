{ config, pkgs, pkgs-unstable ? null, inputs, lib, ... }:

{

  # NetworkManager, its DNS and nm-applet all live in core/networking.nix.


  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    llmnr = "false";
    extraConfig = ''
      Cache=yes
      DNSStubListener=yes
    '';
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.tempAddresses = "disabled";
  networking.firewall.enable = true;
  networking.enableIPv6 = false;

    


  environment.systemPackages = 

# stable packages
    (with pkgs; [
      ethtool
      iperf3
      mtr
    ])

    ++

#Unstable packages (if available)
    (lib.optionals (pkgs-unstable != null) (with pkgs-unstable; [


    ]));


}
