{ pkgs, ... }:

let
  speedtree = import ../derivations/speedtree.nix { inherit pkgs; };
in
{
  config.home-manager.sharedModules = [
    {
      home.packages = (with pkgs; [
        discord
        google-chrome
        celluloid
        pureref
        claude
        nixlymedia
        spotify
        vlc
        onlyoffice-desktopeditors
        pavucontrol
      ]) ++ [ speedtree ];
    }
  ];
}
