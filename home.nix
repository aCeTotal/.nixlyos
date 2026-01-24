{ config, pkgs, inputs, lib, ... }:

{

    imports = [
      # programs
      ./modules/user/git.nix
      ./modules/user/bash.nix
      ./modules/user/btop.nix
      ./modules/user/starship.nix
      ./modules/user/alacritty.nix
      ./modules/user/env.nix
      ./modules/user/thunar_exo.nix
      ./modules/user/dunst.nix
      ./modules/core/nixlytile_config.nix
    ];

    home = {
    username = "total";
    homeDirectory = "/home/total";
    stateVersion = "24.05";
    };
    
    programs.bash.shellAliases = {
      "update" = "cd $HOME/.nixlyos/ && sudo nixos-rebuild boot --flake .#nixlyos";
      "upgrade" = "cd $HOME/.nixlyos/ && nix flake update && sudo nixos-rebuild boot --flake .#nixlyos";
      "nixly" = "cd $HOME/.nixlyos/";
      "c" = "claude";
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

    # Overwrites existing home-manager file
    xdg.configFile."mimeapps.list".force = true;
}
