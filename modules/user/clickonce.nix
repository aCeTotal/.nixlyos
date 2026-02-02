{ config, pkgs, lib, ... }:

let
  # Wine med staging patches for bedre .NET-støtte
  winePackage = pkgs.wineWowPackages.stagingFull;

  # ClickOnce launcher script - håndterer både URLer og lokale filer
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

    # Initialiser wine prefix hvis den ikke finnes
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

    # Fjern file:// prefix hvis det finnes
    INPUT=$(echo "$INPUT" | ${pkgs.gnused}/bin/sed 's|^file://||')

    # Opprett temp-mappe for nedlasting
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    # Sjekk om input er en lokal fil eller URL
    if [ -f "$INPUT" ]; then
      echo "Behandler lokal fil: $INPUT"
      APP_FILE="$INPUT"
      # Prøv å finne base URL fra filen selv
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

    # Parse manifest for å finne deployment provider og app-navn
    CODEBASE=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+' "$APP_FILE" | head -1 || true)

    if [ -z "$CODEBASE" ]; then
      CODEBASE=$(${pkgs.gnused}/bin/sed -n 's/.*codebase="\([^"]*\)".*/\1/p' "$APP_FILE" | head -1)
    fi

    # Håndter relative URLer
    if [[ ! "$CODEBASE" =~ ^https?:// ]]; then
      URL_BASE=$(echo "$BASE_URL" | ${pkgs.gnused}/bin/sed 's|/[^/]*$|/|')
      CODEBASE="$URL_BASE$CODEBASE"
    fi

    echo "Fant deployment manifest: $CODEBASE"

    # Last ned deployment manifest
    DEPLOY_FILE="$TMPDIR/deploy.manifest"
    ${pkgs.curl}/bin/curl -L -k -o "$DEPLOY_FILE" "$CODEBASE"

    # Finn assembly identity og codebase for selve applikasjonen
    APP_CODEBASE=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.exe\.manifest' "$DEPLOY_FILE" | head -1 || true)

    if [ -z "$APP_CODEBASE" ]; then
      APP_CODEBASE=$(${pkgs.gnused}/bin/sed -n 's/.*codebase="\([^"]*\.exe\.manifest\)".*/\1/p' "$DEPLOY_FILE" | head -1)
    fi

    # Beregn base URL for nedlasting
    MANIFEST_BASE=$(echo "$CODEBASE" | ${pkgs.gnused}/bin/sed 's|/[^/]*$|/|')

    if [[ ! "$APP_CODEBASE" =~ ^https?:// ]]; then
      APP_MANIFEST_URL="$MANIFEST_BASE$APP_CODEBASE"
    else
      APP_MANIFEST_URL="$APP_CODEBASE"
    fi

    echo "App manifest URL: $APP_MANIFEST_URL"

    # Last ned app manifest
    APP_MANIFEST="$TMPDIR/app.manifest"
    ${pkgs.curl}/bin/curl -L -k -o "$APP_MANIFEST" "$APP_MANIFEST_URL"

    # Finn alle filer som må lastes ned
    APP_DIR="$TMPDIR/app"
    mkdir -p "$APP_DIR"

    # Last ned hovedapplikasjonen (.exe.deploy eller .exe)
    EXE_FILE=$(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.exe(\.deploy)?' "$APP_MANIFEST" | head -1 || true)

    if [ -z "$EXE_FILE" ]; then
      EXE_FILE=$(${pkgs.gnused}/bin/sed -n 's/.*codebase="\([^"]*\.exe[^"]*\)".*/\1/p' "$APP_MANIFEST" | head -1)
    fi

    APP_BASE=$(echo "$APP_MANIFEST_URL" | ${pkgs.gnused}/bin/sed 's|/[^/]*$|/|')

    echo "Laster ned applikasjonsfiler..."
    ${pkgs.libnotify}/bin/notify-send "ClickOnce" "Laster ned applikasjon..."

    # Last ned exe-filen
    if [ -n "$EXE_FILE" ]; then
      EXE_URL="$APP_BASE$EXE_FILE"
      LOCAL_EXE="$APP_DIR/$(basename "$EXE_FILE" .deploy)"
      echo "Laster ned: $EXE_URL"
      ${pkgs.curl}/bin/curl -L -k -o "$LOCAL_EXE" "$EXE_URL"

      # Last ned tilhørende DLLer
      for DLL in $(${pkgs.gnugrep}/bin/grep -oP 'codebase="\K[^"]+\.dll(\.deploy)?' "$APP_MANIFEST" || true); do
        DLL_URL="$APP_BASE$DLL"
        LOCAL_DLL="$APP_DIR/$(basename "$DLL" .deploy)"
        echo "Laster ned: $DLL_URL"
        ${pkgs.curl}/bin/curl -L -k -o "$LOCAL_DLL" "$DLL_URL" 2>/dev/null || true
      done

      # Last ned config-filer
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

  # Desktop entry for MIME-håndtering
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
    # Wine for å kjøre Windows-applikasjoner
    winePackage

    # Winetricks for å installere .NET Framework
    winetricks

    # ClickOnce launcher
    clickonce-launcher
    clickonce-desktop

    # Nyttige verktøy
    cabextract
    curl
    libnotify
  ];

  # MIME-type assosiasjoner
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

  # MIME-type definisjon
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

  # Desktop entry må også være i applications-mappen
  xdg.dataFile."applications/clickonce-launcher.desktop".source =
    "${clickonce-desktop}/share/applications/clickonce-launcher.desktop";


  # Aktiveringsskript som kjører etter rebuild
  home.activation.updateClickOnceMime = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Oppdater MIME-database
    if [ -d "$HOME/.local/share/mime" ]; then
      ${pkgs.shared-mime-info}/bin/update-mime-database $HOME/.local/share/mime 2>/dev/null || true
    fi

    # Oppdater desktop database
    if [ -d "$HOME/.local/share/applications" ]; then
      ${pkgs.desktop-file-utils}/bin/update-desktop-database $HOME/.local/share/applications 2>/dev/null || true
    fi
  '';
}
