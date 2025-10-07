
{ inputs, config, pkgs, pkgs-stable, ... }:

{
    # Try local hardware-configuration.nix; if missing, fall back to the
    # host's /etc/nixos/hardware-configuration.nix to allow testing on
    # an existing installation. If neither exists, proceed without it.
    imports = [
        ./hardware-configuration.nix
        ./modules/core/default.nix
        ./modules/system/ly.nix
        ./modules/system/hyprland.nix
        ./modules/system/system_services.nix
        # MSI EC kernel driver support
        ./modules/system/msi-ec.nix
        # WinBoat disabled
      ];


    networking.hostName = "nixlytest"; 

    # Provide a system-wide exo helper for Alacritty so exo-open can always find it
    environment.etc."xdg/xfce4/helpers/Alacritty.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Alacritty
      Comment=Terminal Emulator
      Exec=${pkgs.alacritty}/bin/alacritty
      TryExec=${pkgs.alacritty}/bin/alacritty
      Icon=Alacritty
      NoDisplay=true
      X-XFCE-Category=TerminalEmulator
      X-XFCE-Binaries=alacritty
      StartupNotify=true
    '';

    system.stateVersion = "25.05"; 
}
