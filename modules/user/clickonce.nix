{ config, pkgs, lib, ... }:

let
  # Wine with staging patches for better .NET support.
  winePackage = pkgs.wineWow64Packages.stagingFull;

  # ClickOnce launcher, handling both URLs and local files.
  clickonce-launcher = pkgs.writeShellScriptBin "clickonce-launcher" ''
    #!/usr/bin/env bash
    set -euo pipefail

    WINEPREFIX="$HOME/.wine-clickonce"
    export WINEPREFIX

    # Logging
    LOG_FILE="$HOME/.clickonce-launcher.log"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "=== ClickOnce Launcher startet: $(date) ==="
    echo "Input: $*"

    # Initialise the wine prefix if missing.
    if [ ! -d "$WINEPREFIX" ]; then
      echo "Initialiserer Wine prefix..."
      ${winePackage}/bin/wineboot --init
      ${winePackage}/bin/wineserver --wait
      echo "Wine prefix opprettet: $WINEPREFIX"
      ${pkgs.libnotify}/bin/notify-send "ClickOnce" "Wine prefix opprettet. Kjør: WINEPREFIX=$WINEPREFIX winetricks dotnet48"
    fi

    INPUT="$1"

    if [ -z "$INPUT" ]; then
      echo "Bruk: clickonce-launcher <url-eller-fil>"
      exit 1
    fi

    # Strip any file:// prefix.
    INPUT=$(echo "$INPUT" | ${pkgs.gnused}/bin/sed 's|^file://||')

    # Temp dir for downloads.
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    # Local file or URL?
    if [ -f "$INPUT" ]; then
      echo "Behandler lokal fil: $INPUT"
      APP_FILE="$INPUT"
      # Try to find the base URL from the file itself.
      BASE_URL=$(${pkgs.gnugrep}/bin/grep -oP '<deploymentProvider[^>]*codebase="\K[^"]+' "$APP_FILE" | head -1 || true)
      if [ -z "$BASE_URL" ]; then
        BASE_URL=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+' "$APP_FILE" | head -1 || true)
      fi
    else
      echo "Laster ned ClickOnce-manifest: $INPUT"
      APP_FILE="$TMPDIR/app.application"
      ${pkgs.curl}/bin/curl -L -k -o "$APP_FILE" "$INPUT"
      BASE_URL="$INPUT"
    fi

    # Parse the manifest for deployment provider and app name.
    CODEBASE=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+' "$APP_FILE" | head -1 || true)

    if [ -z "$CODEBASE" ]; then
      CODEBASE=$(${pkgs.gnused}/bin/sed -n 's/.*codebase="\([^"]*\)".*/\1/p' "$APP_FILE" | head -1)
    fi

    # Handle relative URLs.
    if [[ ! "$CODEBASE" =~ ^https?:// ]]; then
      URL_BASE=$(echo "$BASE_URL" | ${pkgs.gnused}/bin/sed 's|/[^/]*$|/|')
      CODEBASE="$URL_BASE$CODEBASE"
    fi

    echo "Fant deployment manifest: $CODEBASE"

    # Download the deployment manifest.
    DEPLOY_FILE="$TMPDIR/deploy.manifest"
    ${pkgs.curl}/bin/curl -L -k -o "$DEPLOY_FILE" "$CODEBASE"

    # Find the application's assembly identity and codebase.
    APP_CODEBASE=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.exe\.manifest' "$DEPLOY_FILE" | head -1 || true)

    if [ -z "$APP_CODEBASE" ]; then
      APP_CODEBASE=$(${pkgs.gnused}/bin/sed -n 's/.*codebase="\([^"]*\.exe\.manifest\)".*/\1/p' "$DEPLOY_FILE" | head -1)
    fi

    # Compute the download base URL.
    MANIFEST_BASE=$(echo "$CODEBASE" | ${pkgs.gnused}/bin/sed 's|/[^/]*$|/|')

    if [[ ! "$APP_CODEBASE" =~ ^https?:// ]]; then
      APP_MANIFEST_URL="$MANIFEST_BASE$APP_CODEBASE"
    else
      APP_MANIFEST_URL="$APP_CODEBASE"
    fi

    echo "App manifest URL: $APP_MANIFEST_URL"

    # Download the app manifest.
    APP_MANIFEST="$TMPDIR/app.manifest"
    ${pkgs.curl}/bin/curl -L -k -o "$APP_MANIFEST" "$APP_MANIFEST_URL"

    # Find every file to download.
    APP_DIR="$TMPDIR/app"
    mkdir -p "$APP_DIR"

    # Download the main application.
    EXE_FILE=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.exe(\.deploy)?' "$APP_MANIFEST" | head -1 || true)

    if [ -z "$EXE_FILE" ]; then
      EXE_FILE=$(${pkgs.gnused}/bin/sed -n 's/.*codebase="\([^"]*\.exe[^"]*\)".*/\1/p' "$APP_MANIFEST" | head -1)
    fi

    APP_BASE=$(echo "$APP_MANIFEST_URL" | ${pkgs.gnused}/bin/sed 's|/[^/]*$|/|')

    echo "Laster ned applikasjonsfiler..."
    ${pkgs.libnotify}/bin/notify-send "ClickOnce" "Laster ned applikasjon..."

    # Download the exe.
    if [ -n "$EXE_FILE" ]; then
      EXE_URL="$APP_BASE$EXE_FILE"
      LOCAL_EXE="$APP_DIR/$(basename "$EXE_FILE" .deploy)"
      echo "Laster ned: $EXE_URL"
      ${pkgs.curl}/bin/curl -L -k -o "$LOCAL_EXE" "$EXE_URL"

      # Download the accompanying DLLs.
      for DLL in $(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.dll(\.deploy)?' "$APP_MANIFEST" || true); do
        DLL_URL="$APP_BASE$DLL"
        LOCAL_DLL="$APP_DIR/$(basename "$DLL" .deploy)"
        echo "Laster ned: $DLL_URL"
        ${pkgs.curl}/bin/curl -L -k -o "$LOCAL_DLL" "$DLL_URL" 2>/dev/null || true
      done

      # Download config files.
      for CFG in $(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.config(\.deploy)?' "$APP_MANIFEST" || true); do
        CFG_URL="$APP_BASE$CFG"
        LOCAL_CFG="$APP_DIR/$(basename "$CFG" .deploy)"
        echo "Laster ned: $CFG_URL"
        ${pkgs.curl}/bin/curl -L -k -o "$LOCAL_CFG" "$CFG_URL" 2>/dev/null || true
      done

      echo "Starter applikasjon: $LOCAL_EXE"
      ${pkgs.libnotify}/bin/notify-send "ClickOnce" "Starter $(basename "$LOCAL_EXE")..."
      cd "$APP_DIR"
      ${winePackage}/bin/wine "$LOCAL_EXE"
    else
      echo "Kunne ikke finne executable i manifestet"
      ${pkgs.libnotify}/bin/notify-send -u critical "ClickOnce" "Kunne ikke finne executable i manifestet"
      cat "$APP_MANIFEST"
      exit 1
    fi
  '';

  # Desktop entry for MIME handling.
  clickonce-desktop = pkgs.makeDesktopItem {
    name = "clickonce-launcher";
    desktopName = "ClickOnce Launcher";
    comment = "Kjør ClickOnce-applikasjoner via Wine";
    exec = "${clickonce-launcher}/bin/clickonce-launcher %u";
    icon = "application-x-ms-application";
    terminal = false;
    type = "Application";
    categories = [ "Utility" "System" ];
    mimeTypes = [
      "application/x-ms-application"
      "application/x-ms-xbap"
      "application/vnd.ms-xpsdocument"
      "x-scheme-handler/clickonce"
    ];
    extraConfig = {
      NoDisplay = "false";
      StartupNotify = "true";
    };
  };

in
{
  home.packages = with pkgs; [
    # Wine runs the Windows applications.
    winePackage

    # Winetricks installs .NET Framework.
    winetricks

    # ClickOnce launcher.
    clickonce-launcher
    clickonce-desktop

    # Utilities
    cabextract
    curl
    libnotify
  ];

  # MIME type associations.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-ms-application" = [ "clickonce-launcher.desktop" ];
      "application/x-ms-xbap" = [ "clickonce-launcher.desktop" ];
      "x-scheme-handler/clickonce" = [ "clickonce-launcher.desktop" ];
    };
    associations.added = {
      "application/x-ms-application" = [ "clickonce-launcher.desktop" ];
      "application/x-ms-xbap" = [ "clickonce-launcher.desktop" ];
    };
  };

  # MIME type definition.
  xdg.dataFile."mime/packages/clickonce.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-ms-application">
        <comment>ClickOnce Application</comment>
        <comment xml:lang="no">ClickOnce-applikasjon</comment>
        <glob pattern="*.application"/>
        <magic priority="50">
          <match type="string" offset="0:256" value="&lt;?xml"/>
        </magic>
      </mime-type>
    </mime-info>
  '';

  # The desktop entry must also live in the applications dir.
  xdg.dataFile."applications/clickonce-launcher.desktop".source =
    "${clickonce-desktop}/share/applications/clickonce-launcher.desktop";


  # Activation script, run after each rebuild.
  home.activation.updateClickOnceMime = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Update the MIME database.
    if [ -d "$HOME/.local/share/mime" ]; then
      ${pkgs.shared-mime-info}/bin/update-mime-database $HOME/.local/share/mime 2>/dev/null || true
    fi

    # Update the desktop database.
    if [ -d "$HOME/.local/share/applications" ]; then
      ${pkgs.desktop-file-utils}/bin/update-desktop-database $HOME/.local/share/applications 2>/dev/null || true
    fi
  '';
}
