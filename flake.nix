{
    description = "NixlyOS";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
        nixos-hardware.url = "github:NixOS/nixos-hardware/master";
        home-manager.url = "github:nix-community/home-manager/release-25.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        nixlypkgs.url = "github:aCeTotal/nixlypkgs";
        nixlypkgs.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, ... }:
        let
            system = "x86_64-linux";
            pkgsStable = import nixpkgs {
                inherit system;
                overlays = [ inputs.nixlypkgs.overlays.default ];
                config = { allowUnfree = true; };
            };
            pkgsUnstable = import nixpkgs-unstable {
                inherit system;
                config = { allowUnfree = true; };
            };
        in {
            nixosConfigurations = {
                nixlyos = nixpkgs.lib.nixosSystem {
                    inherit system;
                    specialArgs = {
                        inherit inputs system;
                        pkgs-stable = pkgsStable;
                        pkgs-unstable = pkgsUnstable;
                    };
                    modules = [
                        {
                            nixpkgs.overlays = [ inputs.nixlypkgs.overlays.default ];
                            nixpkgs.config.allowUnfree = true;
                        }
                        ./configuration.nix
                        home-manager.nixosModules.home-manager {
                            home-manager = {
                                extraSpecialArgs = {
                                  inherit inputs system;
                                  pkgs-unstable = pkgsUnstable;
                                };
                                useGlobalPkgs = true;
                                useUserPackages = true;
                                backupFileExtension = "backup";
                                users.total = import ./home.nix;
                            };
                        }
                    ];
                };
            };

        };
}
