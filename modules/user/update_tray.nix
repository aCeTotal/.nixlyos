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

  # nixlytile-trayen ignorerer SNI Status=Passive, saa ikonet kan ikke
  # "gjemme seg" selv — prosessen maa vaere av naar ingen oppdatering er
  # klar. Path-uniten starter den kun naar pending-flagget finnes;
  # scriptet avslutter selv naar flagget forsvinner.
  systemd.user.paths.nixly-update-tray = {
    Unit.Description = "Start update-trayikon naar prevalidert oppdatering ligger klar";
    Path.PathExists = "/var/lib/nixly-update/pending";
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.nixly-update-tray = {
    Unit.Description = "NixlyOS update tray icon";
    Service = {
      ExecStart = "${nixly-update-tray}/bin/nixly-update-tray";
      # Kan starte foer compositor/trayen er oppe ved boot med pending
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
