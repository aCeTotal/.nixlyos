{ config, pkgs, inputs, lib, ... }:

{

    imports = [
      # No user/steam.nix: its wildcard CompatToolMapping at priority 250 broke
      # the Steam Linux Runtime, and autoconfig.nix now owns all Steam config.
      ./modules/user/blender_setup.nix
      # programs
      ./modules/user/git.nix
      ./modules/user/bash.nix
      ./modules/user/btop.nix
      ./modules/user/starship.nix
      ./modules/user/alacritty.nix
      ./modules/user/update_tray.nix
      ./modules/user/nixlytile.nix
      ./modules/user/env.nix
      ./modules/user/gtk.nix
      ./modules/user/qt.nix
      ./modules/core/emulator_config.nix
      ./modules/core/audio_priority.nix
      ./modules/user/emulator_playlists.nix
      ./modules/user/caveman.nix
      ./modules/user/claude.nix
      ./modules/user/discord_rpc.nix
    ];

    home = {
    username = "total";
    homeDirectory = "/home/total";
    stateVersion = "24.05";
    };
    
    programs.bash.shellAliases = {
      "update" = "bash $HOME/.nixlyos/scripts/update.sh";
      "pin-nixpkgs" = "bash $HOME/.nixlyos/scripts/detect-hw.sh $HOME/.nixlyos && nixos-rebuild boot --sudo --flake $HOME/.nixlyos#nixlyos";
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

    # basePath satisfies the home-manager module defaults.
    accounts.calendar.basePath = ".calendar";
    accounts.contact.basePath = ".contacts";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # The login keyring is auto-unlocked via PAM.
    home.file.".local/share/keyrings/default".text = "login";
}
