{ pkgs, lib, ... }:

{
  # Ensure ~/.local/bin is on PATH for sessions
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Wrapper script to always launch a fresh Chrome profile quickly
  home.file.".local/bin/chrome-fresh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Find real Chrome binary (from Nix store)
      CHROME_BIN="$(printenv CHROME_BIN || true)"
      if [ -z "$CHROME_BIN" ]; then
        CHROME_BIN="$(command -v google-chrome-stable || true)"
      fi
      if [ -z "$CHROME_BIN" ]; then
        echo "google-chrome-stable not found in PATH" >&2
        exit 127
      fi

      # Create a temporary, empty profile directory for a truly fresh session
      PROFILE_DIR=$(mktemp -d -t chrome-fresh.XXXXXX)
      cleanup() {
        # Best-effort cleanup; Chrome fully releases on exit
        rm -rf "$PROFILE_DIR" 2>/dev/null || true
      }
      trap cleanup EXIT INT TERM

      exec "$CHROME_BIN" \
        --user-data-dir="$PROFILE_DIR" \
        --no-first-run \
        --no-default-browser-check \
        --disable-session-crashed-bubble \
        --disable-extensions \
        --disable-sync \
        --disable-background-networking \
        --new-window \
        "$@"
    '';
  };

  # Override the desktop entry so launchers (e.g., wofi) use the wrapper
  home.file.".local/share/applications/google-chrome.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Name=Google Chrome
    GenericName=Web Browser
    Comment=Access the Internet
    Exec=chrome-fresh %U
    StartupNotify=true
    Terminal=false
    Icon=google-chrome
    Type=Application
    Categories=Network;WebBrowser;
    StartupWMClass=Google-chrome
    MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;application/x-chrome-extension;
  '';
}
