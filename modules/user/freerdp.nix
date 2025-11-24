{ config
, lib
, pkgs
, pkgs-unstable ? null
, ... }:

let
  remminaPkg =
    if pkgs-unstable != null && pkgs-unstable ? remmina
    then pkgs-unstable.remmina
    else pkgs.remmina;

  startScript = pkgs.writeShellScript "freerdp-autostart" ''
    set -euo pipefail

    # Preferred autostart profile locations
    REMMINA_PROFILE1="${config.home.homeDirectory}/.config/remmina/autostart.remmina"
    REMMINA_PROFILE2="${config.home.homeDirectory}/.config/freerdp/autostart.remmina"

    run_client() {
      exec remmina "$@"
    }

    # 1) If a .remmina profile exists, use it directly
    if [ -f "$REMMINA_PROFILE1" ]; then
      echo "Starting Remmina using $REMMINA_PROFILE1"
      run_client -c "$REMMINA_PROFILE1"
      exit 0
    fi
    if [ -f "$REMMINA_PROFILE2" ]; then
      echo "Starting Remmina using $REMMINA_PROFILE2"
      run_client -c "$REMMINA_PROFILE2"
      exit 0
    fi

    # 2) Otherwise, allow simple env var driven connection via remmina URI
    #    FREERDP_SERVER=host[:port]
    #    FREERDP_USER=user (optional)
    if [ -n ''${FREERDP_SERVER:-} ]; then
      uri="rdp://"
      if [ -n ''${FREERDP_USER:-} ]; then
        uri+="$FREERDP_USER@"
      fi
      uri+="$FREERDP_SERVER"
      echo "Starting Remmina to $uri"
      run_client -c "$uri"
      exit 0
    fi

    echo "No autostart .remmina profile and no FREERDP_SERVER set; skipping Remmina autostart." >&2
    exit 0
  '';
in
{
  # Ensure Remmina client is installed
  home.packages = [ remminaPkg ];

  # Provide a commented template RDP file for convenience
  home.file.".config/freerdp/README.txt".text = ''
    Autostart Remmina on login by creating one of these files:
      ${config.home.homeDirectory}/.config/remmina/autostart.remmina
      ${config.home.homeDirectory}/.config/freerdp/autostart.remmina

    The file must be a valid Remmina profile (.remmina). You can create and save a profile from Remmina UI and then copy/link it here.

    Alternatively, set environment variables before your session starts and a simple RDP URI will be used:
      FREERDP_SERVER=your-server:3389
      FREERDP_USER=YOUR_USER

    This will run:
      remmina -c "rdp://YOUR_USER@your-server:3389" (user part omitted if not set)

    Note:
      - If you have an .rdp file, import it into Remmina and save as a .remmina profile, then point autostart.remmina to it.
  '';

  # Autostart as a per-user systemd service once the graphical session is up
  systemd.user.services."freerdp-autostart" = {
    Unit = {
      Description = "Auto-start Remmina client if configured";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe startScript;
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [ "PATH=${lib.makeBinPath [ remminaPkg pkgs.coreutils pkgs.bash ]}:$PATH" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
