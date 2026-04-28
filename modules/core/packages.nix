{ pkgs, ... }:

let
  speedtree = import ../derivations/speedtree.nix { inherit pkgs; };
in
{
  config.home-manager.sharedModules = [
    {
      home.packages = (with pkgs; [
        discord
        brave
        firefox
        google-chrome
        gimp
        celluloid
        pureref
        claude
        spotify
        vlc
        onlyoffice-desktopeditors
        pavucontrol
        (blender_nixly.override { cudaSupport = true; })
      ]) ++ [ speedtree ];
    }
  ];
}
