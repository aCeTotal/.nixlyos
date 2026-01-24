{
  description = "NixlyOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixlypkgs.url = "path:/home/total/dev_nixly/nixlypkgs";
    nixlypkgs.inputs.nixpkgs.follows = "nixpkgs-stable"; # overlay følger stable
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nixpkgs-stable,
    nixlypkgs,
    home-manager,
    nixos-hardware,
    ...
  }:
  let
    system = "x86_64-linux";

    # Stable-pakker med overlay fra nixlypkgs
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
      overlays = [ nixlypkgs.overlays.default ];
    };
  in {
    nixosConfigurations.nixlyos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs system pkgs-stable;
      };

      modules = [
        ./configuration.nix

        nixos-hardware.nixosModules.common-pc

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;      # bruker stable+overlay
            useUserPackages = true;
            backupFileExtension = "backup";

            extraSpecialArgs = {
              inherit inputs system pkgs-stable;
            };

            users.total = import ./home.nix;
          };
        }
      ];
    };
  };
}

