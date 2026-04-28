{ config, lib, pkgs, ... }:

# KDE Plasma 6 konfig: KWin tiling med gaps via polonium auto-tiler.
# gapsInner = mellom vinduer, gapsOuter = mot skjermkant.

{
  environment.etc."xdg/kwinrc".text = ''
    [Plugins]
    poloniumEnabled=true

    [Script-polonium]
    borders=1
    engineType=0
    gapsInner=8
    gapsOuter=8
    insertionPoint=0
    layoutTimeout=300
    maximizeSingle=false
    pollSize=10
    timerDelay=10

    [Windows]
    Placement=Centered
    BorderlessMaximizedWindows=true

    [Tiling]
    padding=8
  '';
}
