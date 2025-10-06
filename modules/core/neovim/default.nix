{ config, lib, pkgs, pkgs-unstable ? null, ... }:

let
  nvimConfig = ./nvim;
in {
  # Install Neovim the standard way and make it available system-wide
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    # Use default Neovim from current nixpkgs; our LSP config
    # falls back to lspconfig on older versions automatically.
    # defaultEditor is already set elsewhere; keep defaults minimal here
  };

  # Deploy a pure-Lua Neovim config to ~/.config/nvim for all HM users
  home-manager.sharedModules = [
    {
      xdg.configFile."nvim" = {
        source = nvimConfig;
        recursive = true;
      };
    }
  ];
}
