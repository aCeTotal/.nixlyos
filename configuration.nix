
{ inputs, config, pkgs, pkgs-stable, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./modules/core/default.nix
        ./modules/system/ly.nix
        ./modules/system/hyprland.nix
        ./modules/system/system_services.nix
        ./modules/system/msi-ec.nix
      ];


    networking.hostName = "nixlytest"; 

    system.stateVersion = "25.05"; 
}
