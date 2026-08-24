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

  # The tray ignores SNI Status=Passive, so the icon cannot hide itself and the
  # process only runs while the pending flag exists.
  systemd.user.paths.nixly-update-tray = {
    Unit.Description = "Start update-trayikon naar prevalidert oppdatering ligger klar";
    Path.PathExists = "/var/lib/nixly-update/pending";
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.nixly-update-tray = {
    Unit = {
      Description = "NixlyOS update tray icon";
      # Uten ordering starter path-uniten oss foer compositoren har
      # display -> GTK segfaulter i widget-oppretting ved hver boot.
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${nixly-update-tray}/bin/nixly-update-tray";
      # It can start before the tray is up at boot.
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
