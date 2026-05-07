{ config, pkgs, lib, ... }:

let
  # Theme: Minimal Dark for Steam (117⭐, dark, modern, customizable, not WIP).
  # Lives at ${SteamPath}/steamui/skins/<dirname>/skin.json — Millennium reads
  # the dir name as the theme identifier (themes.activeTheme).
  minimalDark = pkgs.fetchFromGitHub {
    owner = "SaiyajinK";
    repo  = "Minimal-Dark-for-Steam";
    rev   = "root";
    hash  = "sha256-KAWsbISQBInaIwRpKkmUfaQBnGg30zrgJNgt2xBi6xQ=";
  };

  # Plugin: Extendium v2.0.3 (Chrome-extension support — bundles SteamDB,
  # Augmented Steam, uBlock Origin, etc.). Pre-built release zip — no
  # node/typescript build needed.
  extendium = pkgs.fetchzip {
    url    = "https://github.com/BossSloth/Extendium/releases/download/v2.0.3/extendium-2.0.3.zip";
    hash   = "sha256-VRyvNKN3eL74/EBnp9rfQjj1UWzZ4cXSupCIMlIgX8M=";
    stripRoot = true;
  };

  # Pre-seed Millennium's settings so theme + plugin are active on first
  # launch, without manual UI clicks. Millennium merges defaults into this
  # file via ConfigManager::MergeDefaults — our keys survive.
  millenniumConfig = builtins.toJSON {
    general = {
      injectJavascript = true;
      injectCSS = true;
      checkForMillenniumUpdates = true;
      checkForPluginAndThemeUpdates = true;
      onMillenniumUpdate = 1;
      millenniumUpdateChannel = "stable";
      shouldShowThemePluginUpdateNotifications = true;
      accentColor = "DEFAULT_ACCENT_COLOR";
    };
    misc = { hasShownWelcomeModal = true; };
    themes = {
      activeTheme = "Minimal-Dark-for-Steam";
      allowedStyles = true;
      allowedScripts = true;
    };
    plugins = {
      enabledPlugins = [ "extendium" ];
    };
    notifications = {
      showNotifications = true;
      showUpdateNotifications = true;
      showPluginNotifications = true;
    };
  };
in
{
  # Theme: read-only symlink into Steam's skins dir. Millennium reads
  # skin.json + CSS from here; per-user choices (Conditions, colors) are
  # stored in ~/.config/millennium/config.json, not in the theme dir.
  home.file.".local/share/Steam/steamui/skins/Minimal-Dark-for-Steam".source = minimalDark;

  # Plugin: read-only symlink into Millennium's plugins dir. Millennium
  # discovers plugin.json + lua backend automatically.
  home.file.".local/share/millennium/plugins/extendium".source = extendium;

  # Seed Millennium config exactly once. If the user later toggles plugins
  # or swaps themes via the UI, Millennium rewrites this file — we MUST
  # NOT clobber that on every rebuild. Hence: only seed when missing.
  home.activation.seedMillenniumConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CFG_DIR="$HOME/.config/millennium"
      CFG_FILE="$CFG_DIR/config.json"
      if [ ! -f "$CFG_FILE" ]; then
        mkdir -p "$CFG_DIR"
        cat > "$CFG_FILE" <<'JSON'
${millenniumConfig}
JSON
      fi
    '';
}
