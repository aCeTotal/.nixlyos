{ pkgs, lib, ... }:

{
  imports = [
    ./clipman.nix
    ./dolphin.nix
  ];

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    libnotify
    sway-contrib.grimshot
    swappy
    swaybg
    swaylock-effects
    networkmanagerapplet
    blueman
    clipman
    fuzzel
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.kio-admin
    kdePackages.ark
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.breeze-icons
    kdePackages.qtwayland
    samba
    cifs-utils
    foot
    dunst
    brightnessctl
    playerctl
    wireplumber
    xwayland-satellite
    socat
    jq
    nixly_launcher
  ]
  ++ lib.optionals (pkgs ? mcontrolcenter) [ pkgs.mcontrolcenter ];

  home.file."Pictures/wallpapers/beach.jpg".source = ../../wallpapers/beach.jpg;

  xdg.configFile."nixlytile/config.kdl".text = ''
    // nixlytile config (managed by home-manager: modules/user/nixlytile.nix)
    // Loaded at startup: $XDG_CONFIG_HOME/nixlytile/config.kdl
    // Hot-reload: pkill -USR1 nixlytile

    appearance {
        gaps 4
        border-px 1
        smartgaps           false
        sloppy-focus        true
        bypass-surface-visibility false
        gaps-enabled        true
        root-color          "#222222ff"
        border-color        "#595959ff"
        focus-color         "#00beffff"
        urgent-color        "#ff0000ff"
        fullscreen-bg       "#1a1a1aff"
        resize-factor       0.0002
        resize-interval-ms  8
        resize-min-pixels   1.0
        resize-ratio-epsilon 0.001
        lock-cursor         false
    }

    input {
        keyboard {
            layout       "no"
            repeat-delay 300
            repeat-rate  100
        }
        touchpad {
            tap                     true
            tap-and-drag            true
            drag-lock               true
            natural-scroll          true
            disable-while-typing    true
            left-handed             false
            middle-button-emulation false
            scroll-method   "2fg"
            click-method    "button-areas"
            send-events     "enabled"
            accel-profile   "adaptive"
            accel-speed     0.0
            button-map      "lrm"
        }
    }

    modkey      "Super"
    monitorkey  "Ctrl"

    wallpaper "~/.nixlyos/wallpapers/beach.jpg"

    // "info" i produksjon — debug betyr per-event formatering + logg-IO
    // i frame-pathen.  Sett "debug" midlertidig ved feilsøking.
    log-level "info"

    // Autostart — one process per entry.
    autostart "thunar --daemon"
    autostart "swaybg -i \"$HOME/.nixlyos/wallpapers/beach.jpg\" -m fill"
    autostart "nm-applet --indicator"
    autostart "blueman-applet"
    autostart "xwayland-satellite"
    autostart "sh -c 'wl-paste --type text --watch clipman store --no-persist'"
    autostart "sh -c 'wl-paste --primary --type text --watch clipman store --no-persist'"
    autostart "appd"
    autostart "mcontrolcenter"

    // ───────── keybindings ─────────
    // Applications
    bind "Super+Return"       "spawn" "alacritty"
    bind "Super+p"            "spawn" "apptoggle"
    bind "Super+g"            "spawn" "fuzzel"
    bind "Super+i"            "spawn" "fuzzel"
    bind "Super+e"            "spawn" "dolphin"
    bind "Super+Escape"       "spawn" "nixly-lockscreen"
    bind "Super+F12"          "spawn" "nixly-lockscreen"
    // bind "Super+BackSpace"    "spawn" "google-chrome-stable --ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations"
    bind "Super+BackSpace"    "spawn" "firefox"
    bind "Super+s"            "spawn" "grimshot copy area"
    bind "Print"            "spawn" "grimshot copy area"
    bind "Shift+Print"      "spawn" "grimshot copy output"

    // Window management
    bind "Super+q"            "killclient"
    bind "Super+Shift+Q"      "quit"
    bind "Super+Shift+space"  "togglefloating"
    bind "Super+c"            "togglefloating"
    bind "Super+f"            "maximize-column"
    bind "Super+Shift+F"      "togglefullscreen"
    bind "Super+b"            "togglestatusbar"

    // Focus navigation
    bind "Super+h"            "focus-column-dir"             -1
    bind "Super+l"            "focus-column-dir"             1
    bind "Super+Left"         "focus-column-dir"             -1
    bind "Super+Right"        "focus-column-dir"             1
    bind "Super+j"            "focus-window-in-column-dir"   1
    bind "Super+k"            "focus-window-in-column-dir"   -1
    bind "Super+Up"           "focus-workspace-dir"          -1
    bind "Super+Down"         "focus-workspace-dir"          1

    // Window movement
    bind "Super+Shift+H"      "move-column-dir"              -1
    bind "Super+Shift+L"      "move-column-dir"              1
    bind "Super+Shift+J"      "move-window-in-column-dir"    1
    bind "Super+Shift+K"      "move-window-in-column-dir"    -1
    bind "Super+Shift+Left"   "move-column-dir"              -1
    bind "Super+Shift+Right"  "move-column-dir"              1
    bind "Super+Shift+Up"     "move-window-in-column-dir"    -1
    bind "Super+Shift+Down"   "move-window-in-column-dir"    1

    // Alt-direction: move tile within current workspace
    bind "Alt+h"            "move-column-dir"              -1
    bind "Alt+l"            "move-column-dir"              1
    bind "Alt+Left"         "move-column-dir"              -1
    bind "Alt+Right"        "move-column-dir"              1
    bind "Alt+k"            "move-window-in-column-dir"    -1
    bind "Alt+j"            "move-window-in-column-dir"    1
    bind "Alt+Up"           "move-window-in-column-dir"    -1
    bind "Alt+Down"         "move-window-in-column-dir"    1

    // Column width / consume / expel
    bind "Super+r"            "switch-preset-column-width"
    bind "Super+a"            "swap-window-dir"              -1
    bind "Super+d"            "swap-window-dir"              1
    bind "Super+x"            "expel-window-from-column"
    bind "Super+Ctrl+Left"    "switch-preset-column-width"
    bind "Super+Ctrl+Right"   "switch-preset-column-width"
    bind "Super+Ctrl+Up"      "center-column"
    bind "Super+Ctrl+Down"    "maximize-column"

    // Workspaces 1..9
    bind "Super+1" "focus-workspace-n" 0
    bind "Super+2" "focus-workspace-n" 1
    bind "Super+3" "focus-workspace-n" 2
    bind "Super+4" "focus-workspace-n" 3
    bind "Super+5" "focus-workspace-n" 4
    bind "Super+6" "focus-workspace-n" 5
    bind "Super+7" "focus-workspace-n" 6
    bind "Super+8" "focus-workspace-n" 7
    bind "Super+9" "focus-workspace-n" 8
    bind "Super+0" "focus-workspace-n" 9
    bind "Super+Shift+1" "move-client-to-ws-n" 0
    bind "Super+Shift+2" "move-client-to-ws-n" 1
    bind "Super+Shift+3" "move-client-to-ws-n" 2
    bind "Super+Shift+4" "move-client-to-ws-n" 3
    bind "Super+Shift+5" "move-client-to-ws-n" 4
    bind "Super+Shift+6" "move-client-to-ws-n" 5
    bind "Super+Shift+7" "move-client-to-ws-n" 6
    bind "Super+Shift+8" "move-client-to-ws-n" 7
    bind "Super+Shift+9" "move-client-to-ws-n" 8
    bind "Super+Shift+0" "move-client-to-ws-n" 9
    bind "Super+Tab"     "focus-last-workspace"

    // Multi-monitor
    bind "Super+comma"           "focusmon"        "left"
    bind "Super+period"          "focusmon"        "right"
    bind "Super+Shift+less"      "tagmon"          "left"
    bind "Super+Shift+greater"   "tagmon"          "right"
    bind "MonitorMod+Up"       "warptomonitor"   "up"
    bind "MonitorMod+Down"     "warptomonitor"   "down"
    bind "MonitorMod+Left"     "warptomonitor"   "left"
    bind "MonitorMod+Right"    "warptomonitor"   "right"
    bind "MonitorMod+Shift+exclam"     "tagtomonitornum" 0
    bind "MonitorMod+Shift+at"         "tagtomonitornum" 1
    bind "MonitorMod+Shift+numbersign" "tagtomonitornum" 2
    bind "MonitorMod+Shift+dollar"     "tagtomonitornum" 3

    // VT switch (Ctrl+Alt+F1..F12)
    bind "Ctrl+Alt+XF86Switch_VT_1"  "chvt" 1
    bind "Ctrl+Alt+XF86Switch_VT_2"  "chvt" 2
    bind "Ctrl+Alt+XF86Switch_VT_3"  "chvt" 3
    bind "Ctrl+Alt+XF86Switch_VT_4"  "chvt" 4
    bind "Ctrl+Alt+XF86Switch_VT_5"  "chvt" 5
    bind "Ctrl+Alt+XF86Switch_VT_6"  "chvt" 6
    bind "Ctrl+Alt+XF86Switch_VT_7"  "chvt" 7
    bind "Ctrl+Alt+XF86Switch_VT_8"  "chvt" 8
    bind "Ctrl+Alt+XF86Switch_VT_9"  "chvt" 9
    bind "Ctrl+Alt+XF86Switch_VT_10" "chvt" 10
    bind "Ctrl+Alt+XF86Switch_VT_11" "chvt" 11
    bind "Ctrl+Alt+XF86Switch_VT_12" "chvt" 12
    bind "Ctrl+Alt+Terminate_Server" "quit"
  '';
}
