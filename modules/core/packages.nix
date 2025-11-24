{ config, lib, pkgs-stable ? null, pkgs-unstable ? null, ... }:

let
  hmStablePkgs = lib.optionals (pkgs-stable != null) (with pkgs-stable; [
    discord
    gimp
    celluloid
    google-chrome
    pureref
    teams-for-linux
    alacritty
    citrix_workspace
  ]);

  # Packages from the unstable channel (provided via flake specialArgs)
  hmUnstablePkgs = lib.optionals (pkgs-unstable != null) (with pkgs-unstable; [
    codex
    libreoffice-fresh
    (blender.override { cudaSupport = true; })
  ]);

  systemStablePkgs = lib.optionals (pkgs-stable != null) (with pkgs-stable; [
    btop
    gcc        # provides cc/gcc for Treesitter and native plugins
    gnumake    # required by telescope-fzf-native and similar
    clang-tools # provides clangd LSP server from nix rather than Mason
    nixd       # Nix language server; avoids Mason install issues
    nodePackages_latest.bash-language-server # bashls via Nix instead of Mason
    nodejs
  ]);
in {
  config = let
    hmPkgs = hmStablePkgs ++ hmUnstablePkgs;
  in {
    # Home Manager: apply packages to all HM users via sharedModules
    home-manager.sharedModules = lib.mkIf (hmPkgs != [ ]) [
      { home.packages = hmPkgs; }
    ];

    # System: stable-only, not via Home Manager
    environment.systemPackages = systemStablePkgs;
  };
}
