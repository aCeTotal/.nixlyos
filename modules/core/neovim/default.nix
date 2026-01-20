{ config, lib, pkgs, ... }:

let
  nvimConfig = ./nvim;
in {
  # Install Neovim system-wide
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # Deploy pure-Lua Neovim config to ~/.config/nvim
  home-manager.sharedModules = [
    {
      xdg.configFile."nvim" = {
        source = nvimConfig;
        recursive = true;
      };

      # LSP servers and development tools
      home.packages = with pkgs; [
        # Build tools (for treesitter parsers)
        gcc
        gnumake

        # C/C++
        clang-tools  # clangd
        bear  # generate compile_commands.json from Makefile

        # Web
        vscode-langservers-extracted  # HTML, CSS, JSON, ESLint
        nodePackages.typescript-language-server  # TypeScript/JavaScript

        # PHP
        phpactor

        # Python
        pyright
        python3Packages.black  # formatter

        # Lua
        lua-language-server

        # Nix
        nil  # Nix LSP
        nixpkgs-fmt  # Nix formatter

        # Bash
        nodePackages.bash-language-server
        shellcheck
        shfmt

        # YAML
        yaml-language-server

        # General tools
        ripgrep  # for Telescope live_grep
        fd  # for Telescope find_files
        lazygit  # for LazyGit plugin
      ];
    }
  ];
}
