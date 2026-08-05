{
  description = "NixlyOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixlypkgs.url = "github:aCeTotal/nixlypkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    totalvim = {
      url = "github:aCeTotal/totalvim";
      flake = false;
    };
    mnw.url = "github:Gerg-L/mnw";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      nixlypkgs,
      home-manager,
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

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = permittedInsecure;
          # De gamle NVIDIA-branchene (legacy_470 og eldre) krever eksplisitt
          # lisensgodkjenning i tillegg til allowUnfree — uten den feiler
          # eval paa Kepler-og-eldre-maskiner. Se gpu/nvidia_legacy.nix.
          nvidia.acceptLicense = true;
        };
        overlays = [
          nixlypkgs.overlays.default
          inputs.nix-cachyos-kernel.overlays.default
          (import ./pkgs/proton-ge/overlay.nix)
        ];
      };

      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = permittedInsecure;
        };
      };

      totalvimSrc = inputs.totalvim;

      totalvimVimPlugin = pkgs.callPackage (totalvimSrc + "/plugins/totalvim") { };

      totalvimPkg = inputs.mnw.lib.wrap {
        inherit pkgs;
        inputs = {
          self.legacyPackages.${system}.vimPlugins.totalvim = totalvimVimPlugin;
        };
      } (totalvimSrc + "/nix/mnw");
    in
    {
      nixosConfigurations.nixlyos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs system totalvimPkg;
          pkgs-unstable = pkgsUnstable;
        };

        modules = [
          ({ ... }: { nixpkgs.pkgs = pkgs; })

          ./configuration.nix

          nixos-hardware.nixosModules.common-pc
          nixlypkgs.nixosModules.nixlypkgs
          inputs.lanzaboote.nixosModules.lanzaboote
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupCommand = ''mv --force "$1" "$1.backup"'';
              extraSpecialArgs = {
                inherit inputs system totalvimPkg;
                pkgs-unstable = pkgsUnstable;
              };
              users.total = import ./home.nix;
            };
          }
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nix
          nixos-rebuild
          git
          nix-output-monitor
        ];
      };
    };
}
