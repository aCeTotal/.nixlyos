{ pkgs, ... }:

{
    home.file.".config/hypr/conf/animations.conf".text = ''

    # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
    #
    animations {
    enabled = yes

# Define Settings For Animation Bezier Curve
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = liner, 1, 1, 1, 1

    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 1, liner
    animation = borderangle, 1, 30, liner, loop
    animation = fade, 1, 10, default
    animation = workspaces, 1, 5, wind
    }

    '';

    home.file.".config/hypr/conf/autostart.conf".text = ''

# Execute your favorite apps at launch
      exec-once = swaybg -i "$HOME/.dotfiles/wallpapers/current.jpg"
      exec-once = ~/.config/hypr/xdg-portal-hyprland
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
      '';

    home.file.".config/hypr/conf/binds.conf".text = ''

# Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more

# SUPER key
$mainMod = SUPER

# Actions
bind = $mainMod, RETURN, exec, alacritty  #open the terminal
bind = $mainMod, Q, killactive, # close the active window
bind = $mainMod, P, exec, rofi -show run
bind = $mainMod, BACKSPACE, exec, brave
bind = $mainMod, F, fullscreen,
bind = $mainMod, E, exec, thunar # Show the graphical file browser
bind = $mainMod, V, togglefloating, # Allow a window to float
bind = $mainMod, D, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle
bind = $mainMod, S, exec, grimblast --notify --cursor copysave area
bind = , Print, exec, grimblast --notify --cursor copysave area

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l # Move focus left
bind = $mainMod, right, movefocus, r # Move focus right
bind = $mainMod, up, movefocus, u # Move focus up
bind = $mainMod, down, movefocus, d # Move focus down

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1 # Switch to workspace 1
bind = $mainMod, 2, workspace, 2 # Switch to workspace 2
bind = $mainMod, 3, workspace, 3 # Switch to workspace 3
bind = $mainMod, 4, workspace, 4 # Switch to workspace 4
bind = $mainMod, 5, workspace, 5 # Switch to workspace 5
bind = $mainMod, 6, workspace, 6 # Switch to workspace 6
bind = $mainMod, 7, workspace, 7 # Switch to workspace 7
bind = $mainMod, 8, workspace, 8 # Switch to workspace 8
bind = $mainMod, 9, workspace, 9 # Switch to workspace 9
bind = $mainMod, 0, workspace, 10 # Switch to workspace 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1 #  Move window to workspace 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2 #  Move window to workspace 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3 #  Move window to workspace 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4 #  Move window to workspace 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5 #  Move window to workspace 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6 #  Move window to workspace 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7 #  Move window to workspace 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8 #  Move window to workspace 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9 #  Move window to workspace 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10 #  Move window to workspace 10

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1 # Scroll workspaces 
bind = $mainMod, mouse_up, workspace, e-1 # Scroll workspaces

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow # Move window
bindm = $mainMod, mouse:273, resizewindow # Resize window

    '';

    home.file.".config/hypr/conf/decoration.conf".text = ''

# See https://wiki.hyprland.org/Configuring/Variables/ for more
      decoration {
        rounding = 5
          blur {
            enabled = true
              size = 3
              passes = 1
          }
      }


    '';
    home.file.".config/hypr/conf/environments.conf".text = ''

      # XDG Desktop Portal
      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_TYPE,wayland
      env = XDG_SESSION_DESKTOP,Hyprland

      # QT
      env = QT_QPA_PLATFORM,wayland;xcb
      env = QT_QPA_PLATFORMTHEME,qt6ct
      env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
      env = QT_AUTO_SCREEN_SCALE_FACTOR,1

      # GTK
      env = GDK_SCALE,1

      # Mozilla
      env = MOZ_ENABLE_WAYLAND,1

      # Set the cursor size for xcursor
      env = XCURSOR_SIZE,21

      # Disable appimage launcher by default
      env = APPIMAGELAUNCHER_DISABLE,1

      # OZONE
      env = OZONE_PLATFORM,wayland

      # For KVM virtual machines
      # env = WLR_NO_HARDWARE_CURSORS, 1
      # env = WLR_RENDERER_ALLOW_SOFTWARE, 1
    '';

    home.file.".config/hypr/conf/general.conf".text = ''

      # See https://wiki.hyprland.org/Configuring/Variables/ for more
      general {
        gaps_in = 5
          gaps_out = 5
          border_size = 1
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
          resize_on_border = true
      }
    '';

    home.file.".config/hypr/conf/gestures.conf".text = ''

      # See https://wiki.hyprland.org/Configuring/Variables/ for more
      gestures {
        workspace_swipe = true
      }
    '';

    home.file.".config/hypr/conf/input.conf".text = ''

      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
      input {
        kb_layout = no
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =

          repeat_delay = 300
          repeat_rate = 50

          follow_mouse = 1

          touchpad {
            natural_scroll = false
          }

        sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
      }

    '';

    home.file.".config/hypr/conf/layouts.conf".text = ''

      dwindle {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true # you probably want this
      }

    master {
    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    # new_status = master
    }

    '';

    home.file.".config/hypr/conf/misc.conf".text = ''

      # See https://wiki.hyprland.org/Configuring/Variables/ for more
      misc {
        disable_hyprland_logo = true
          disable_splash_rendering = true
      }

    '';
    home.file.".config/hypr/conf/monitors.conf".text = ''

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor=,highrr,auto,1

    '';

    home.file.".config/hypr/hyprland.conf".text = ''


#  _   _                  _                 _  
# | | | |_   _ _ __  _ __| | __ _ _ __   __| | 
# | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` | 
# |  _  | |_| | |_) | |  | | (_| | | | | (_| | 
# |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_| 
#        |___/|_|                              
#  
# ----------------------------------------------------- 
# Full documentation https://wiki.hyprland.org

    source = ~/.config/hypr/conf/monitors.conf
    source = ~/.config/hypr/conf/autostart.conf
    source = ~/.config/hypr/conf/environments.conf
    source = ~/.config/hypr/conf/input.conf
    source = ~/.config/hypr/conf/general.conf
    source = ~/.config/hypr/conf/decoration.conf
    source = ~/.config/hypr/conf/animations.conf
    source = ~/.config/hypr/conf/layouts.conf
    source = ~/.config/hypr/conf/gestures.conf
    source = ~/.config/hypr/conf/misc.conf
    source = ~/.config/hypr/conf/binds.conf
    '';






    home.packages = with pkgs; [
        swaybg
        rofi
        xfce.thunar
        foot
    ];

}
