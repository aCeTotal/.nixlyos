{
  description = "NixlyOS";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/master";
    nixlypkgs.url = "github:aCeTotal/nixlypkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
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

    # opencollada-blender removed from nixpkgs 2026-04-26 (now a throw alias).
    # nixlypkgs blender variants still list it in their callPackage args, which
    # forces the throw even with colladaSupport disabled. Stub the attr at the
    # overlay level so callPackage resolves it without firing the alias.
    blenderNoCollada = final: prev: {
      opencollada-blender = null;
      blender_nvidia = prev.blender_nvidia.override { colladaSupport = false; };
      blender_amd    = prev.blender_amd.override    { colladaSupport = false; };
      blender_intel  = prev.blender_intel.override  { colladaSupport = false; };
    };

    pkgs = import nixpkgsUnstableSrc {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
      overlays = [
        nixlypkgs.overlays.default
        blenderNoCollada
        inputs.nix-cachyos-kernel.overlays.default
        (import ./pkgs/proton-ge/overlay.nix)
      ];
    };

    pkgsStable = import nixpkgsStableSrc {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
    };

    # totalvim fully locked via nixpkgs.txt (totalvimsrc/mnw/totalvim revs)
    # so system upgrades can't touch it. Bump revs there to update totalvim.
    totalvimSrc = builtins.fetchTree {
      type = "github";
      owner = "aCeTotal";
      repo = "totalvim";
      rev = revs.totalvimsrc;
    };

    mnw = builtins.getFlake "github:Gerg-L/mnw/${revs.mnw}";

    # Dedicated nixpkgs pin for totalvim (revs.totalvim in nixpkgs.txt) so
    # neovim, plugins and LSP servers stay fixed when stable/unstable move.
    pkgsTotalvim = import (fetchNixpkgs revs.totalvim) {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = permittedInsecure;
      };
    };

    totalvimVimPlugin = pkgsTotalvim.callPackage (totalvimSrc + "/plugins/totalvim") {};

    totalvimPkg = mnw.lib.wrap {
      pkgs = pkgsTotalvim;
      inputs = {
        self.legacyPackages.${system}.vimPlugins.totalvim = totalvimVimPlugin;
      };
    } (totalvimSrc + "/nix/mnw");

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
