{ config, pkgs, inputs, lib, ... }:

{

    imports = [
      ./modules/user/steam.nix
      ./modules/user/blender_setup.nix
      # programs
      ./modules/user/git.nix
      ./modules/user/bash.nix
      ./modules/user/btop.nix
      ./modules/user/starship.nix
      ./modules/user/alacritty.nix
      ./modules/user/niri.nix
      ./modules/user/env.nix
      ./modules/user/gtk.nix
      ./modules/core/emulator_config.nix
      ./modules/user/caveman.nix
      ./modules/user/claude.nix
    ];

    home = {
    username = "total";
    homeDirectory = "/home/total";
    stateVersion = "24.05";
    };
    
    programs.bash.shellAliases = {
      "update" = "bash $HOME/.nixlyos/pkgs/proton-ge/bump.sh && nix flake update nixlypkgs proton-cachyos --flake $HOME/.nixlyos && sudo nixos-rebuild boot --flake $HOME/.nixlyos#nixlyos";
      "upgrade" = "bash $HOME/.nixlyos/pkgs/proton-ge/bump.sh && nix flake update --flake $HOME/.nixlyos && sudo nixos-rebuild boot --flake $HOME/.nixlyos#nixlyos";
      "pin-nixpkgs" = "sudo nixos-rebuild boot --flake $HOME/.nixlyos#nixlyos";
      "nixly" = "cd $HOME/.nixlyos/";
      "c" = "claude --dangerously-skip-permissions";
      "ai" = "nixly-ai";
    };


    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
     };
    };

    # Calendar/accounts: set basePath to satisfy HM module defaults
    accounts.calendar.basePath = ".calendar";
    accounts.contact.basePath = ".contacts";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Set login keyring as default (auto-unlocked via PAM on login)
    home.file.".local/share/keyrings/default".text = "login";
}
