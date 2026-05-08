{
  description = "NixlyOS";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/master";
    nixlypkgs.url = "github:aCeTotal/nixlypkgs";
    totalvim.url = "github:aCeTotal/totalvim";
    mnw.url = "github:Gerg-L/mnw";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    proton-cachyos.url = "github:powerofthe69/proton-cachyos-nix";
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
  };

  outputs = inputs@{
    self,
    nixos-hardware,
    nixlypkgs,
    home-manager,
    ...
  }:
  let
    system = "x86_64-linux";

    revs =
      let
        content = builtins.readFile ./nixpkgs.txt;
        lines = builtins.filter builtins.isString (builtins.split "\n" content);
        parseLine = line:
          let m = builtins.match "[[:space:]]*([a-zA-Z]+)[[:space:]]*=[[:space:]]*([a-f0-9]+)[[:space:]]*" line;
          in if m == null then null
             else { name = builtins.elemAt m 0; value = builtins.elemAt m 1; };
        pairs = builtins.filter (x: x != null) (map parseLine lines);
      in builtins.listToAttrs pairs;

    fetchNixpkgs = rev: builtins.fetchTree {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      inherit rev;
    };

    nixpkgsUnstableSrc = fetchNixpkgs revs.unstable;
    nixpkgsStableSrc   = fetchNixpkgs revs.stable;

    permittedInsecure = [
      "freeimage-unstable-2021-11-01"
      "electron-29.4.6"
      "dotnet-sdk-6.0.428"
      "dotnet-runtime-6.0.36"
      "dotnet-sdk-wrapped-6.0.428"
      "libxml2-2.13.8"
      "libsoup-2.74.3"
    ];

    openldapNoCheck = final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
    };

    pkgs = import nixpkgsUnstableSrc {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
      overlays = [
        nixlypkgs.overlays.default
        openldapNoCheck
        inputs.nix-cachyos-kernel.overlays.default
        inputs.proton-cachyos.overlays.default
        inputs.millennium.overlays.default
        # Inject Millennium into nixly_steam's underlying steam so the wrapper
        # launches the Millennium-patched client. CEF GPU-compositing flag is
        # baked into nixly_steam's default derivation upstream.
        (final: prev: {
          nixly_steam = prev.nixly_steam.override {
            steam = final.millennium-steam;
          };
        })
      ];
    };

    pkgsStable = import nixpkgsStableSrc {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
    };

    totalvimVimPlugin = pkgsStable.callPackage (inputs.totalvim + "/plugins/totalvim") {};

    totalvimPkg = inputs.mnw.lib.wrap {
      pkgs = pkgsStable;
      inputs = {
        self.legacyPackages.${system}.vimPlugins.totalvim = totalvimVimPlugin;
      };
    } (inputs.totalvim + "/nix/mnw");

    lib = pkgs.lib;
  in {
    nixosConfigurations.nixlyos = import (nixpkgsUnstableSrc + "/nixos/lib/eval-config.nix") {
      inherit system lib;

      specialArgs = { inherit inputs system totalvimPkg; };

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
            extraSpecialArgs = { inherit inputs system totalvimPkg; };
            users.total = import ./home.nix;
          };
        }
      ];
    };
  };
}
