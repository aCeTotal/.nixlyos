
{ inputs, config, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./modules/core/default.nix
      ];

    networking.hostName = "nixlytest"; 
    system.stateVersion = "25.05"; 
}
