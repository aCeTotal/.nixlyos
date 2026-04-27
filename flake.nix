{
  description = "NixlyOS";

  inputs = {
    nixpkgs = {
    url = "github:NixOS/nixpkgs/nixos-unstable";
    };  
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-hyprland.url = "github:NixOS/nixpkgs/16aacb40e80d4a84d11a31a16c9093c8817159a2";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixlypkgs.url = "github:aCeTotal/nixlypkgs";
    nixlypkgs.inputs.nixpkgs.follows = "nixpkgs";
    totalvim.url = "github:aCeTotal/totalvim";
    totalvim.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-hyprland,
    nixlypkgs,
    home-manager,
    nixos-hardware,
    ...
  }:
  let
    system = "x86_64-linux";

    pkgs-hyprland = import nixpkgs-hyprland {
      inherit system;
      config.allowUnfree = true;
    };

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

    # Skip flaky openldap syncrepl test
    openldapNoCheck = final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
    };

    # Unstable-pakker med overlay fra nixlypkgs
    pkgs-unstable = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
      overlays = [ nixlypkgs.overlays.default openldapNoCheck ];
    };
  in {
    nixosConfigurations.nixlyos = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs system pkgs-stable pkgs-unstable pkgs-hyprland;
      };

      modules = [
        ./configuration.nix
        { nixpkgs.overlays = [ openldapNoCheck ]; }

        nixos-hardware.nixosModules.common-pc
        nixlypkgs.nixosModules.nixlypkgs
        inputs.lanzaboote.nixosModules.lanzaboote

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";

            extraSpecialArgs = {
              inherit inputs system pkgs-stable pkgs-unstable pkgs-hyprland;
            };

            users.total = import ./home.nix;
          };
        }
      ];
    };
  };
}

