{ pkgs, pkgs-hyprland, ... }:

{

     home.packages = [
        pkgs-hyprland.hyprpaper
    ];


    home.file.".config/hypr/hyprpaper.conf".text = ''

    preload = /home/total/.nixlyos/wallpapers/beach.jpg
    wallpaper = , /home/total/.nixlyos/wallpapers/beach.jpg

    '';

}
