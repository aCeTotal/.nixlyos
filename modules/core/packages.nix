{ config, lib, pkgs-stable ? null, nixpkgs-unstable ? null, system ? null, ... }:

let
  hmStablePkgs = lib.optionals (pkgs-stable != null) (with pkgs-stable; [
    discord
    google-chrome
    teams-for-linux
    alacritty
  ]);

  # Instantiate unstable lazily only when provided
  unstable = if nixpkgs-unstable != null && system != null
             then nixpkgs-unstable.legacyPackages.${system}
             else null;
  hmUnstablePkgs = lib.optionals (unstable != null) (with unstable; [
    codex
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
