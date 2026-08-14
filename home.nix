{ config, pkgs, inputs, lib, ... }:

{

    imports = [
      # user/steam.nix fjernet: skrev wildcard-CompatToolMapping med
      # priority 250 (som autoconfig.nix dokumenterer at oedelegger Steam
      # Linux Runtime-installasjon). modules/core/steam/autoconfig.nix
      # eier all Steam-config naa, ved hver oppstart.
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

    # Calendar/accounts: set basePath to satisfy HM module defaults
    accounts.calendar.basePath = ".calendar";
    accounts.contact.basePath = ".contacts";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Set login keyring as default (auto-unlocked via PAM on login)
    home.file.".local/share/keyrings/default".text = "login";
}
