
{ inputs, config, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./modules/core/default.nix
        inputs.nixlypkgs.nixosModules.nixly_lockscreen
      ];

    networking.hostName = "nixlytest"; 
    system.stateVersion = "25.05"; 
}
