{ pkgs, ... }:

let
  nixly-update-tray = pkgs.python3Packages.buildPythonApplication {
    pname = "nixly-update-tray";
    version = "1.0";
    format = "other";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk3 pkgs.libayatana-appindicator ];
    propagatedBuildInputs = [ pkgs.python3Packages.pygobject3 ];
    installPhase = ''
      install -Dm755 ${./nixly-update-tray.py} $out/bin/nixly-update-tray
    '';
  };
in
{
  home.packages = [ nixly-update-tray ];
}
