{ pkgs, ... }:

{
  config.home-manager.sharedModules = [
    {
      home.packages = with pkgs; [
        discord
        firefox
        google-chrome
        celluloid
        pureref
        claude
        nixlymedia
        spotify
        vlc
        onlyoffice-desktopeditors
        pavucontrol
      ];
    }
  ];
}
