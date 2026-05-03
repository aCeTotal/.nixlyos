{ pkgs, lib, ... }:

{
  imports = [
    ./waybar.nix
    ./clipman.nix
    ./dolphin.nix
    ./idle-lock.nix
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

  # Auto-pick highest resolution × refresh rate for every connected output.
  # Re-runs on DRM hotplug via udevadm monitor.
  home.file.".local/bin/niri-set-max-mode.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      apply() {
        niri msg --json outputs | jq -r '
          to_entries[] |
          .key as $name |
          (.value.modes // []) as $modes |
          if ($modes | length) > 0 then
            ($modes | sort_by(.width * .height, .refresh_rate) | last) as $b |
            "\($name)|\($b.width)x\($b.height)@\($b.refresh_rate/1000)"
          else empty end
        ' | while IFS="|" read -r name mode; do
          niri msg output "$name" mode "$mode" >/dev/null 2>&1 || true
        done
      }

      apply

      if [ "''${1:-}" = "--watch" ]; then
        exec udevadm monitor --udev --subsystem-match=drm 2>/dev/null \
          | while read -r line; do
              case "$line" in
                *change*card*) sleep 0.4; apply ;;
              esac
            done
      fi
    '';
  };

  home.file.".config/niri/config.kdl".text = ''
    // Niri config translated from prior Hyprland setup.
    // Reference: https://yalter.github.io/niri/Configuration:-Overview.html

    input {
        keyboard {
            xkb {
                layout "no"
            }
            repeat-delay 300
            repeat-rate 100
        }

        touchpad {
            tap
            natural-scroll
        }

        mouse {
            accel-speed 0.0
        }

        focus-follows-mouse
        warp-mouse-to-focus
    }

    // Modes auto-picked by niri-set-max-mode.sh (highest WxH × refresh).
    output "DP-1" {
        position x=0 y=0
        scale 1.0
        variable-refresh-rate
    }

    output "eDP-2" {
        scale 1.0
        variable-refresh-rate
    }

    output "HDMI-A-1" {
        scale 1.0
    }

    layout {
        gaps 4
        center-focused-column "never"
        preset-column-widths {
            proportion 0.25
            proportion 0.333
            proportion 0.5
            proportion 0.667
            proportion 0.75
            proportion 1.0
        }
        default-column-width { proportion 0.5; }

        focus-ring {
            width 1
            active-color "#00beff"
            inactive-color "#595959"
        }

        border {
            off
        }

        insert-hint {
            color "#00beff80"
        }
    }

    cursor {
        xcursor-size 28
    }

    environment {
        XCURSOR_SIZE "28"
        DISPLAY ":0"
    }

    prefer-no-csd

    spawn-at-startup "swaybg" "-i" "/home/total/.nixlyos/wallpapers/beach.jpg" "-m" "fill"
    spawn-at-startup "sh" "-c" "$HOME/.local/bin/niri-set-max-mode.sh --watch"
    spawn-at-startup "waybar"
    spawn-at-startup "nm-applet" "--indicator"
    spawn-at-startup "blueman-applet"
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "sh" "-c" "wl-paste --type text --watch clipman store --no-persist"
    spawn-at-startup "sh" "-c" "wl-paste --primary --type text --watch clipman store --no-persist"
    spawn-at-startup "appd"

    screenshot-path "~/Pictures/screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    binds {
        // Window management
        Mod+Q { close-window; }
        Mod+Shift+Q { quit; }
        Mod+Shift+Space { toggle-window-floating; }
        Mod+C { toggle-window-floating; }
        Mod+F { maximize-column; }
        Mod+B { spawn "pkill" "-SIGUSR1" "waybar"; }

        // Focus navigation
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+Left  { focus-column-or-monitor-left; }
        Mod+Right { focus-column-or-monitor-right; }
        Mod+Up    { focus-workspace-up; }
        Mod+Down  { focus-workspace-down; }

        // Window movement
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+L     { move-column-right; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }

        // Column width / consume / expel
        Mod+R     { switch-preset-column-width; }
        Mod+A     { swap-window-left; }
        Mod+D     { swap-window-right; }
        Mod+X     { expel-window-from-column; }
        Mod+Ctrl+Left  { switch-preset-column-width; }
        Mod+Ctrl+Right { switch-preset-column-width; }
        Mod+Ctrl+Up    { center-column; }
        Mod+Ctrl+Down  { maximize-column; }

        // Applications
        Mod+Return       { spawn "alacritty"; }
        Mod+Shift+Return { spawn "foot"; }
        Mod+P            { spawn "apptoggle"; }
        Mod+G            { spawn "fuzzel"; }
        Mod+I            { spawn "fuzzel"; }
        Mod+E            { spawn "dolphin"; }
        Mod+Escape       { spawn "hyprlock"; }
        Mod+BackSpace    { spawn "google-chrome-stable"; }

        // Overview (all tiles across all workspaces)
        Mod+W { toggle-overview; }

        // Re-apply highest mode on all outputs (manual hotplug fallback)
        Mod+Shift+M { spawn "sh" "-c" "$HOME/.local/bin/niri-set-max-mode.sh"; }

        // Screenshot
        Mod+S { spawn "grimshot" "copy" "area"; }
        Print { spawn "grimshot" "copy" "area"; }

        // Clipboard history (moved off Mod+W which is now overview)
        Mod+V { spawn "sh" "-c" "p=$(clipman pick -t CUSTOM --tool=fuzzel --tool-args='--dmenu --prompt=  '); [ -n \"$p\" ] && printf '%s' \"$p\" | wl-copy && printf '%s' \"$p\" | wl-copy --primary"; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }

        Mod+Tab { focus-workspace-previous; }

        // Monitor navigation
        Mod+Comma  { focus-monitor-left; }
        Mod+Period { focus-monitor-right; }
        Mod+Shift+Less    { move-workspace-to-monitor-left; }
        Mod+Shift+Greater { move-workspace-to-monitor-right; }
        Ctrl+Up    { focus-monitor-up; }
        Ctrl+Down  { focus-monitor-down; }
        Ctrl+Left  { focus-monitor-left; }
        Ctrl+Right { focus-monitor-right; }

        // Scroll workspaces with wheel
        Mod+WheelScrollDown { focus-workspace-down; }
        Mod+WheelScrollUp   { focus-workspace-up; }

        // Audio / brightness / media keys
        XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioMicMute      allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
        XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "s" "10%+"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "s" "10%-"; }
        XF86AudioNext         allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPause        allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioPlay         allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioPrev         allow-when-locked=true { spawn "playerctl" "previous"; }
    }

    window-rule {
        match app-id="^pol\\.exe$"
        open-on-workspace "4"
        open-floating true
    }

    window-rule {
        match app-id="^rusty-rain-screensaver$"
        open-fullscreen true
        border { off; }
        focus-ring { off; }
    }

    window-rule {
        match app-id="^dunst$"
        opacity 0.92
    }

    layer-rule {
        match namespace="^notifications$"
        place-within-backdrop false
        block-out-from "screencast"
    }
  '';
}
