{
  description = "NixlyOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixlypkgs.url = "github:aCeTotal/nixlypkgs";
    nixlypkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    nixos-hardware,
    ...
  }:
  let
    system = "x86_64-linux";

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixlyos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs system pkgs-stable;
      };

      modules = [
        {
          nixpkgs = {
            overlays = [ inputs.nixlypkgs.overlays.default ];
            config.allowUnfree = true;
          };
        }

        ./configuration.nix

        nixos-hardware.nixosModules.common-pc

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;   # ← bruker unstable pkgs
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

