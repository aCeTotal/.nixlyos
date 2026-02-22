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

    permittedInsecure = [
      "freeimage-unstable-2021-11-01"
      "electron-29.4.6"
      "dotnet-sdk-6.0.428"
      "dotnet-runtime-6.0.36"
      "dotnet-sdk-wrapped-6.0.428"
      "libxml2-2.13.8"
      "libsoup-2.74.3"
    ];

    # Stable-pakker med overlay fra nixlypkgs
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
      overlays = [ nixlypkgs.overlays.default ];
    };

    # Unstable-pakker
    pkgs-unstable = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
    };
  in {
    nixosConfigurations.nixlyos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs system pkgs-stable pkgs-unstable;
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
              inherit inputs system pkgs-stable pkgs-unstable;
            };

            users.total = import ./home.nix;
          };
        }
      ];
    };
  };
}

