
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

    # WinBoat (nixlypkgs) pulls in electron-36.x which is flagged insecure in nixpkgs 25.05
    # Explicitly permit it so evaluation succeeds when winboat is installed.
    nixpkgs.config.permittedInsecurePackages = [ "" ];
}
