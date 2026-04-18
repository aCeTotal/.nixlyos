{ pkgs, lib, ... }:

let
  opts = import ./nixlytile_options.nix;
in
{

    home.file.".config/nixlytile/config.conf".text = ''
# Nixlytile Configuration File
# Place this file at ~/.config/nixlytile/config.conf
# Lines starting with # are comments
# Format: key = value
#
# Hot-reload: Changes are applied automatically when this file is saved.

# =============================================================================
#                           DESKTOP (Window Manager)
# =============================================================================

# ================= APPEARANCE =================

# Focus follows mouse (1 = enabled, 0 = disabled)
sloppyfocus = 1

# Smart gaps - disable outer gap when only one window (1 = enabled)
smartgaps = 0

# Enable gaps between windows (1 = enabled)
gaps = 1

# Gap size in pixels between windows
gappx = 5

# Window border width in pixels
borderpx = 1

# Lock cursor during resize (1 = lock, 0 = free)
lock_cursor = 0

# Bypass surface visibility optimization (1 = enabled, 0 = disabled)
# bypass_surface_visibility = 0

# ================= COLORS =================
# Colors are in hex format: #RRGGBBAA or #RRGGBB
# Examples: #FF0000FF (red, full opacity), #00FF00 (green)

# Root/desktop background color
rootcolor = #222222FF

# Unfocused window border color
bordercolor = #444444FF

# Focused window border color
focuscolor = #005577FF

# Urgent window border color
urgentcolor = #FF0000FF

# Fullscreen background color
fullscreen_bg = #1A1A1AFF

# ================= STATUSBAR =================

# Statusbar height in pixels
statusbar_height = 26

# Gap at top of statusbar
statusbar_top_gap = 3

# Spacing between status modules
statusbar_module_spacing = 10

# Padding inside status modules
statusbar_module_padding = 8

# Gap between icon and text in status modules
statusbar_icon_text_gap = 6

# Statusbar foreground (text) color
statusbar_fg = #FFFFFFFF

# Statusbar background color (semi-transparent)
statusbar_bg = #00000016

# Popup background color
statusbar_popup_bg = #00000080

# Muted volume indicator color
statusbar_volume_muted_fg = #FF4C4CFF

# Muted microphone indicator color
statusbar_mic_muted_fg = #FF4C4CFF

# Workspace tag background
statusbar_tag_bg = #00000033

# Active workspace tag background
statusbar_tag_active_bg = #1565C0FF

# Hovered workspace tag background
statusbar_tag_hover_bg = #66B3FFAA

# Hover fade animation duration (0 = instant)
statusbar_hover_fade_ms = 0

# Workspace tag padding
statusbar_workspace_padding = 8

# Workspace tag spacing
statusbar_workspace_spacing = 4

# Thumbnail preview height
statusbar_thumb_height = 40

# Thumbnail preview gap
statusbar_thumb_gap = 2

# Thumbnail window color
statusbar_thumb_window = #FFFFFF55

# Force RGBA decode for tray icons (workaround for some apps)
statusbar_tray_force_rgba = 0

# Statusbar font (comma-separated for fallbacks)
# Format: "family:size=N:weight=Bold"
statusbar_font = "monospace:size=16:weight=Bold, monospace:size=16"

# Font letter spacing adjustment
statusbar_font_spacing = 0

# Force font color rendering (1 = enabled)
statusbar_font_force_color = 1

# ================= WALLPAPER & STARTUP =================

# Wallpaper image path (supports ~ and $HOME)
wallpaper = ~/.nixlyos/wallpapers/beach.jpg

# Custom autostart command (overrides default which includes wallpaper)
# If you set this, wallpaper setting is ignored
# autostart = "your-custom-startup-command &"

# ================= KEYBOARD =================

# Key repeat delay in milliseconds
repeat_delay = 250

# Key repeat rate (characters per second)
repeat_rate = 60

# ================= TRACKPAD/MOUSE =================

# Enable tap to click (1 = enabled)
tap_to_click = 1

# Enable tap and drag (1 = enabled)
tap_and_drag = 1

# Enable drag lock (1 = enabled)
drag_lock = 1

# Enable natural scrolling (1 = enabled, reverses scroll direction)
natural_scrolling = 0

# Disable touchpad while typing (1 = enabled)
disable_while_typing = 1

# Left-handed mode (1 = enabled, swaps buttons)
left_handed = 0

# Middle button emulation (1 = enabled)
middle_button_emulation = 0

# Pointer acceleration speed (-1.0 to 1.0)
accel_speed = 0.0

# Acceleration profile: "flat" or "adaptive"
accel_profile = adaptive

# Scroll method: "none", "2fg" (two finger), "edge", "button"
scroll_method = 2fg

# Click method: "none", "button_areas", "clickfinger"
click_method = button_areas

# Tap button map: "lrm" (left/right/middle) or "lmr" (left/middle/right)
button_map = lrm

# ================= RESIZING =================

# Resize factor for mouse resizing
resize_factor = 0.0002

# Minimum interval between resize updates (ms)
resize_interval_ms = 24

# Minimum pointer movement before resize (pixels)
resize_min_pixels = 3.0

# Smallest ratio change to trigger arrange
resize_ratio_epsilon = 0.002

# ================= SEARCH =================

# Minimum characters before starting file search
modal_file_search_minlen = 1

# ================= MODIFIER KEYS =================

# Main modifier key: super (Windows key), alt, ctrl, shift
modkey = super

# Monitor navigation modifier key
monitorkey = ctrl

# ================= SPAWN COMMANDS =================
# These define default programs. Note: these are NOT automatically bound
# to keybindings - they are just convenience variables for the defaults.
# The actual keybindings are defined in the KEYBINDINGS section below
# using "bind = ... spawn <program>".

# Default terminal
terminal = alacritty

# Alternative terminal (for Shift+Enter)
terminal_alt = foot

# Web browser
browser = google-chrome-stable

# File manager
filemanager = thunar

# Application launcher
launcher = wmenu-run

# ================= KEYBINDINGS =================
# Format: bind = modifiers+key action [argument]
#
# Modifiers: super, alt, ctrl, shift, mod (uses modkey)
# You can combine modifiers with +, e.g.: mod+shift+Return
#
# Common keys: Return, space, Tab, Escape, BackSpace, Delete
#              Up, Down, Left, Right, Home, End, Page_Up, Page_Down
#              F1-F12, Print, plus letter/number keys (a-z, 0-9)
#
# Actions and their arguments:
#   quit                    - Exit compositor
#   killclient              - Close focused window
#   spawn <command>         - Run shell command
#   focusstack <+1/-1>      - Focus next/previous window
#   incnmaster <+1/-1>      - Increase/decrease master count
#   setmfact <+/-0.05>      - Adjust master area size
#   zoom                    - Swap focused with master
#   view <tag>              - Switch to tag (1-9, or 'all')
#   tag <tag>               - Move window to tag
#   toggleview <tag>        - Toggle tag visibility
#   toggletag <tag>         - Toggle window's tag
#   togglefloating          - Toggle floating mode
#   togglefullscreen        - Toggle fullscreen
#   togglegaps              - Toggle gaps
#   togglestatusbar         - Toggle statusbar
#   focusmon <direction>    - Focus monitor (1=up, 2=down, 4=left, 8=right)
#   tagmon <direction>      - Move window to monitor (1=up, 2=down, 4=left, 8=right)
#   modal_show              - Open modal (apps tab)
#   modal_show_files        - Open modal directly in file search
#   modal_show_git          - Open modal directly in git projects
#   nixpkgs_show            - Open nixpkgs package installer
#   focusdir <up/down/left/right>     - Focus window in direction
#   swapclients <0-3>       - Swap window (0=left, 1=right, 2=up, 3=down)
#   setratio_h <+/-0.025>   - Adjust horizontal split ratio
#   setratio_v <+/-0.025>   - Adjust vertical split ratio
#   rotate_clients <+1/-1>  - Rotate windows in layout
#   warptomonitor <direction> - Move cursor to monitor (1=up, 2=down, 4=left, 8=right)
#   tagtomonitornum <0-3>   - Move focused window to monitor by number
#   setlayout               - Set/cycle layout
#   togglefullscreenadaptivesync - Toggle fullscreen adaptive sync
#   togglemirror            - Toggle monitor mirroring
#   htpc_mode_toggle        - Toggle HTPC mode
#   gamepanel               - Toggle game performance panel
#   screenshot_begin        - Enter screenshot selection mode
#   chvt <1-12>             - Switch to virtual terminal

# === Window management ===
bind = mod+q killclient
bind = mod+shift+Q quit
bind = mod+shift+space togglefloating
bind = mod+f togglefullscreen
bind = mod+shift+g togglegaps
bind = mod+b togglestatusbar

# === Focus navigation ===
bind = mod+j focusstack +1
bind = mod+k focusstack -1
bind = mod+Up focusdir up
bind = mod+Down focusdir down
bind = mod+Left focusdir left
bind = mod+Right focusdir right

# === Window movement ===
bind = mod+shift+Up swapclients 2
bind = mod+shift+Down swapclients 3
bind = mod+shift+Left swapclients 0
bind = mod+shift+Right swapclients 1
bind = mod+shift+J rotate_clients +1
bind = mod+shift+K rotate_clients -1

# === Layout adjustment ===
bind = mod+h setmfact -0.05
bind = mod+l setmfact +0.05
bind = mod+d incnmaster -1
bind = mod+ctrl+Left setratio_h -0.025
bind = mod+ctrl+Right setratio_h +0.025
bind = mod+ctrl+Up setratio_v -0.025
bind = mod+ctrl+Down setratio_v +0.025

# === Applications ===
# These keybindings launch programs. The 'spawn' action runs shell commands.
# Format: bind = modifiers+key spawn <command>
# Commands can be simple program names or full shell commands with arguments.

# Terminal emulators
bind = mod+Return spawn alacritty
bind = mod+shift+Return spawn foot

# Application launcher / search modal
bind = mod+p modal_show
bind = mod+v modal_show_files
bind = mod+g modal_show_git
bind = mod+i nixpkgs_show

# File manager
bind = mod+e spawn thunar

# Web browser
bind = mod+BackSpace spawn google-chrome-stable

# Screenshot (select region, copies PNG to clipboard)
bind = mod+s screenshot_begin
bind = Print screenshot_begin

# Example additional applications (uncomment to enable):
# bind = mod+n spawn nm-connection-editor
# bind = mod+v spawn pavucontrol
# bind = mod+c spawn code

# Frame pacing statistics panel (slides in from right, shows FPS, latency, etc.)
bind = mod+ctrl+Return gamepanel

# === Workspaces (tags) ===
bind = mod+1 view 1
bind = mod+2 view 2
bind = mod+3 view 4
bind = mod+4 view 8
bind = mod+5 view 16
bind = mod+6 view 32
bind = mod+7 view 64
bind = mod+8 view 128
bind = mod+9 view 256
bind = mod+0 view all

bind = mod+shift+1 tag 1
bind = mod+shift+2 tag 2
bind = mod+shift+3 tag 4
bind = mod+shift+4 tag 8
bind = mod+shift+5 tag 16
bind = mod+shift+6 tag 32
bind = mod+shift+7 tag 64
bind = mod+shift+8 tag 128
bind = mod+shift+9 tag 256
bind = mod+shift+0 tag all

bind = mod+Tab view 0

# === Monitor navigation ===
bind = mod+comma focusmon 4
bind = mod+period focusmon 8
bind = mod+shift+less tagmon 4
bind = mod+shift+greater tagmon 8
bind = ctrl+Up warptomonitor 1
bind = ctrl+Down warptomonitor 2
bind = ctrl+Left warptomonitor 4
bind = ctrl+Right warptomonitor 8

# =============================================================================
#                          HTPC (Home Theater PC)
# =============================================================================

# ================= HTPC MODE =================
# 1 = desktop only (normal window manager)
# 2 = htpc only (controller/TV, starts directly in HTPC mode)
nixlytile_mode = ${toString opts.nixlytileMode}

# Wallpaper to display in HTPC mode (supports ~ and $HOME)
htpc_wallpaper = ~/.nixlyos/wallpapers/htpc.jpg

# HTPC menu pages (1 = show, 0 = hide)
htpc_page_pcgaming = 1
htpc_page_retrogaming = 1
htpc_page_movies = 1
htpc_page_tvshows = 1
htpc_page_quit = 1

# ================= MEDIA SERVER =================
# Connect to a nixlymediaserver instance for Movies & TV Shows.
# The server is auto-discovered via UDP broadcast on the local network.
# Set this manually if auto-discovery fails or the server is on a different subnet.
# Format: IP:port or full URL (http:// prefix is optional)
#
# Examples:
# media_server = 192.168.1.100:8080
# media_server = http://10.0.0.8:8080
# media_server = myserver.local:8080
media_server = http://aceclan.no:8080

# Client download bandwidth limit in Mbps (for transcoded streaming)
# client_download_mbps = 100

# ================= PC GAMING =================
# Configure which gaming services to scan for games in the PC Gaming view.
# The PC Gaming view is accessible from the controller guide menu.
#
# GPU-specific launch parameters are hardcoded in game_launch_params.h
# and automatically applied based on your detected discrete GPU.
# Parameters you set manually in Steam's launch options will NOT be duplicated.

# Enable Steam library scanning (1 = enabled, 0 = disabled)
gaming_steam_enabled = 1

# Enable Heroic Games Launcher scanning (Epic/GOG games)
gaming_heroic_enabled = 1

# Enable Lutris scanning (future support)
gaming_lutris_enabled = 1

# Enable Bottles scanning (future support)
gaming_bottles_enabled = 0

# ================= RETRO GAMING EMULATORS =================
# Maps server emulator tags to launch commands.
# Format: emulator = <tag> <command with %s for ROM path>
# Tags must match what the server returns (nes, snes, n64, etc.)

# Nintendo
emulator = nes Mesen "%s"
emulator = snes Mesen "%s"
emulator = n64 RMG "%s" -f
emulator = gamecube dolphin-emu -e "%s" -b
emulator = wii dolphin-emu -e "%s" -b
emulator = gb mgba -f "%s"
emulator = gbc mgba -f "%s"
emulator = gba mgba -f "%s"
emulator = ds melonDS "%s"
emulator = 3ds azahar "%s"
emulator = wiiu cemu -g "%s" -f
emulator = switch Ryujinx "%s"

# PlayStation
emulator = ps1 mednafen -video.fs 1 -psx.stretch aspect_mult2 -psx.videoip 0 -force_module psx "%s"
emulator = ps2 pcsx2-qt -fullscreen -bigpicture -- "%s"
emulator = ps3 rpcs3 --no-gui --fullscreen "%s"
emulator = psp ppsspp --fullscreen "%s"

# Xbox
emulator = xbox xemu -dvd_path "%s" -full-screen
emulator = xbox360 xenia_canary "%s"

# Sega
emulator = genesis blastem -f "%s"
emulator = mastersystem blastem -m sms -f "%s"
emulator = saturn mednafen -video.fs 1 -ss.stretch aspect_mult2 -ss.videoip 0 -force_module ss "%s"
emulator = dreamcast flycast "%s"
emulator = segacd ares --system "Mega CD" "%s" --fullscreen --no-file-prompt
emulator = gamegear Mesen "%s"
emulator = 32x ares --system "Mega 32X" "%s" --fullscreen --no-file-prompt

# Other
emulator = atari2600 stella -fullscreen "%s"
emulator = tgfx16 Mesen "%s"


        '';

}
