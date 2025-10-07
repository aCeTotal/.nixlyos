{ config, pkgs, inputs, lib, ... }:

{

    imports = [
      # programs
      ./modules/user/git.nix
      ./modules/user/bash.nix
      ./modules/user/btop.nix
      ./modules/user/starship.nix
      ./modules/user/alacritty.nix
      ./modules/user/thunar_exo.nix
      ./modules/user/hyprland.nix
      ./modules/user/dunst.nix
      ./modules/user/virtualisation.nix
      ./modules/user/winboat.nix
    ];

    home = {
    username = "total";
    homeDirectory = "/home/total";
    stateVersion = "24.05";
    };

    # User applications
    home.packages = with pkgs; [
      seahorse
    ];

    
    programs.bash.shellAliases = {
      "update" = "cd $HOME/dev_nixly/.nixlyos/ && sudo nixos-rebuild switch --flake .#nixlyos";
      "upgrade" = "cd $HOME/dev_nixly/.nixlyos/ && nix flake update && sudo nixos-rebuild switch --flake .#nixlyos";
      "nixly" = "cd $HOME/dev_nixly/";  
    };


    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
     };
    };

    # Manage Environment variables
    home.sessionVariables = {
      Editor = "vim";
    };

    # Calendar/accounts: set basePath to satisfy HM module defaults
    accounts.calendar.basePath = ".calendar";
    accounts.contact.basePath = ".contacts";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Notifications: mako removed to test BT popups

    # Also disable Blueman's own Notification plugin via dconf
    dconf.settings."org/blueman/plugins/notification" = {
      enabled = false;
    };

    # Starship konfig håndteres via ./modules/user/starship.nix

}
