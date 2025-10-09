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
      ./modules/user/hyprland.nix
      ./modules/user/dunst.nix
      ./modules/user/virtualisation.nix
      ./modules/user/winstripping.nix
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

      "game" = "cd /mnt/nfs/Bigdisk1/dev/gamedev/Godot/thelastemperor/";

      "start_backend" = "cd /mnt/nfs/Bigdisk1/dev/gamedev/Godot/thelastemperor/ && nix run .#start_backend";
      "start_directory" = "cd /mnt/nfs/Bigdisk1/dev/gamedev/Godot/thelastemperor/ && nix run .#start_directory";
      "start_client" = "cd /mnt/nfs/Bigdisk1/dev/gamedev/Godot/thelastemperor/ && nix run .#start_client";
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

    # Notifications: mako removed to test BT popups

    # Also disable Blueman's own Notification plugin via dconf
    dconf.settings."org/blueman/plugins/notification" = {
      enabled = false;
    };

    # Starship konfig håndteres via ./modules/user/starship.nix

}
