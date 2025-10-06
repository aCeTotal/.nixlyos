{ config, pkgs, nixpkgs-unstable ? null, inputs, lib, ... }:

{

  # NetworkManager setup moved to core/networking.nix
  # networking.networkmanager.enable handled in core
  # networking.networkmanager.dns handled in core

  # nm-applet managed via user service in core/networking.nix

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
  networking.tempAddresses = "default";
  networking.firewall.enable = true;
  networking.enableIPv6 = true;

    


  environment.systemPackages = 

# stable packages
    (with pkgs; [
      ethtool
      iperf3
      mtr
    ])

    ++

#Unstable packages (if available)
    (let unstable = if nixpkgs-unstable != null then nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system} else null;
     in lib.optionals (unstable != null) (with unstable; [


    ]));


}
