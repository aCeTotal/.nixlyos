{ pkgs, lib, ... }:

{
  imports = [
    ./waybar.nix
    ./clipman.nix
    ./dolphin.nix
  ];

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    libnotify
    sway-contrib.grimshot
    swappy
    swaybg
    swaylock-effects
    networkmanagerapplet
    blueman
    clipman
    fuzzel
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.kio-admin
    kdePackages.ark
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.breeze-icons
    kdePackages.qtwayland
    samba
    cifs-utils
    foot
    dunst
    brightnessctl
    playerctl
    wireplumber
    xwayland-satellite
    socat
    jq
    nixly_launcher
  ]
  ++ lib.optionals (pkgs ? mcontrolcenter) [ pkgs.mcontrolcenter ];

  home.file."Pictures/wallpapers/beach.jpg".source = ../../wallpapers/beach.jpg;
}
