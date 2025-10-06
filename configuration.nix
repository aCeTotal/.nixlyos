
{ inputs, config, pkgs, pkgs-stable, ... }:

{
    # Try local hardware-configuration.nix; if missing, fall back to the
    # host's /etc/nixos/hardware-configuration.nix to allow testing on
    # an existing installation. If neither exists, proceed without it.
    imports = [
        ./hardware-configuration.nix
        ./modules/core/default.nix
        ./modules/system/ly.nix
        ./modules/system/hyprland.nix
        ./modules/system/system_services.nix
        # WinBoat system requirements (Docker, kernel modules, groups)
        ./modules/system/winboat.nix
      ];


    networking.hostName = "nixlytest"; 

    system.stateVersion = "25.05"; 
}
