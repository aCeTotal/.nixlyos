{ pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };

  hardware.steam-hardware.enable = true;
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 4;
        inotify = 8192;
        inhibit_screensaver = 1;
        softrealtime = "auto";
      };
      gpu = {
        apply_gpu_optimisations = "auto";
        gpu_device = "auto";
        amd_performance_level = "high";
      };
      custom = {
        start = "''";
        end = "''";
      };
    };
  };

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${lib.concatStringsSep ":" [ "$HOME/.steam/root/compatibilitytools.d" "$HOME/.local/share/Steam/compatibilitytools.d" ]}";
  };

  environment.systemPackages = with pkgs; [
    steamcmd
    gamescope
    mangohud
    goverlay
    vkbasalt
    lutris
    heroic
    bottles
    protonup
    protontricks
    wineWowPackages.staging
    winetricks
    dxvk
    vkd3d
  ];
}

