{ config, pkgs, ... }:

{

     home.packages = with pkgs; [
        nerd-fonts.caskaydia-cove
        font-awesome
        waybar
        procps # for pkill/pgrep used by Waybar signals
    ];


    home.file.".config/waybar/style.css".text = ''

* {
  font-family: "CaskaydiaCove Nerd Font", "Font Awesome 6 Free", "Font Awesome 6 Free Solid";
  font-weight: bold;
  font-size: 16px;
  color: #dcdfe1;
}

#waybar {
  background-color: rgba(0, 0, 0, 0);
  border: none;
  box-shadow: none;
  /* Add inner horizontal padding so rightmost/leftmost modules are not flush with the screen edge */
  padding: 0 8px;
}

#workspaces,
#window,
#tray{
  /*background-color: rgba(29,31,46, 0.95);*/
  background-color: rgba(15,27,53,0.6);
  padding: 4px 6px; /* 保持内部间距 */
  margin-top: 4px; /* 外部间距与 Hyprland gaps_out 匹配 */
  margin-left: 4px; /* 外部间距与 Hyprland gaps_out 匹配 */
  margin-right: 4px; /* 外部间距与 Hyprland gaps_out 匹配 */
  border-radius: 2%;
  border-width: 0px;
  }

#clock,
#custom-power {
  background-color: rgba(15,27,53,0.6);
  margin-top: 4px; /* 与 Hyprland 外间距对齐 */
  margin-left: 4px; /* base gap */
  /*margin-bottom: 4px;*/
  padding: 4px 6px; /* 增加水平内边距，避免图标被裁切 */
  border-radius: 2%;
  border-width: 0px;
}

/* Power menu buttons: use larger gaps between each icon */
#custom-menu,
#custom-menu-lock,
#custom-menu-reboot,
#custom-menu-poweroff{
  background-color: rgba(15,27,53,0.6);
  margin-top: 4px;
  margin-left: 6px; /* balanced spacing between power buttons */
  margin-right: 6px; /* keep away from screen edge */
  padding: 4px 6px; /* more horizontal padding for full icon render */
  border-radius: 2%;
  border-width: 0px;
}

#network,
#custom-lock,
#custom-menu-browser,
#custom-menu-files,
#custom-menu-term{
  background-color: rgba(15,27,53,0.6);
  margin-top: 4px; /* 与 Hyprland 外间距对齐 */
  margin-left: 4px;
  /*margin-bottom: 4px;*/
  padding: 4px 6px; /* 保持内部间距并避免裁切 */
  border-radius: 2%;
  border-width: 0px;
}

#custom-reboot,
#bluetooth,
#battery,
#pulseaudio,
#backlight,
#custom-temperature,
#memory,
#cpu{
  background-color: rgba(15,27,53,0.6);
  margin-top: 4px; /* 与 Hyprland 外间距对齐 */
  margin-left: 4px; /* normalize right-side gap to 4px */
  /*margin-bottom: 4px;*/
  padding: 4px 6px; /* 保持内部间距并避免裁切 */
  border-radius: 2%;
  border-width: 0px;
}

#custpm-temperature.critical,
#pulseaudio.muted {
  color: #FF4040;
  padding-top: 0;
}

/* Mic default look (no background by default to allow full red fill when muted) */
#custom-mic {
  margin-top: 4px;
  margin-left: 4px; /* normalize right-side gap to 4px */
  padding: 4px 6px;
}

/* If class is attached to the module container */
#custom-mic.muted { background-color: #8B0000; color: #ffffff; border-radius: 2%; }
#custom-mic.muted:hover { background-color: #a40000; }
#custom-mic.normal { background-color: rgba(15,27,53,0.6); color: #dcdfe1; border-radius: 2%; }
#custom-mic.normal:hover { background-color: rgba(70, 75, 90, 0.7); }

/* If class is attached to inner label */
#custom-mic .muted { background-color: #8B0000; color: #ffffff; }
#custom-mic .muted:hover { background-color: #a40000; }

/* 鼠标悬停变亮一点 */
#bluetooth:hover,
#network:hover,
/*#tray:hover,*/
#backlight:hover,
#battery:hover,
#pulseaudio:hover,
#custom-mic:hover,
#custom-menu:hover,
#custom-menu-browser:hover,
#custom-menu-files:hover,
#custom-menu-term:hover,
#custom-temperature:hover,
#memory:hover,
#cpu:hover,
#clock:hover,
#custom-lock:hover,
#custom-reboot:hover,
#custom-power:hover,
#custom-menu-lock:hover,
#custom-menu-reboot:hover,
#custom-menu-poweroff:hover,
/*#workspaces:hover,*/
#window:hover {
  background-color: rgba(70, 75, 90, 0.7);
}

/* (removed) fine-tune via CSS; using Pango spaces instead */

/* Power menu open state: make main icon a red X */
#custom-menu.open {
  color: #FF4040;
}

/* 工作区激活状态高亮 */
#workspaces button:hover{
  background-color: rgba(97, 175, 239, 0.2);
  padding: 2px 8px;
  margin: 0 2px;
  border-radius: 2%;
}

#workspaces button.active {
  background-color: #61afef; /* 蓝色高亮 */
  color: #ffffff;
  padding: 2px 8px;
  margin: 0 2px;
  border-radius: 2%;
}

/* 未激活工作区按钮 */
#workspaces button {
  background: transparent;
  border: none;
  color: #888888;
  padding: 2px 8px;
  margin: 0 2px;
  font-weight: bold;
}

#window {
  font-weight: 500;
  font-style: italic;
}


    '';



    home.file.".config/waybar/config.jsonc".text = ''

{
  "layer": "top",
  "position": "top",
  "exclusive": true,
  "height": 32,
  "spacing": 0,
  "modules-left": [
    "hyprland/workspaces",
    "tray"
  ],
  "modules-right": [
    "network",
    "battery",
    "bluetooth",
    "pulseaudio",
    "custom/mic",
    "backlight",
    "memory",
    "cpu",
    "clock",
    "custom/menu-lock",
    "custom/menu-reboot",
    "custom/menu-poweroff",
    "custom/menu"
  ],
  "hyprland/workspaces": {
    "disable-scroll": false,
    "all-outputs": true,
    "format": "{icon}",
    "on-click": "activate",
    "persistent-workspaces": {
    "*":[1,]
    },
    "format-icons": {
      "1": "1",
    }
  },
  "custom/menu": {
    "format": "{}",
    "return-type": "json",
    "signal": 11,
    "interval": 1,
    "exec": "$HOME/.config/waybar/menu_main.sh",
    "tooltip": true,
    "tooltip-format": "Lås / Omstart / Slå av",
    "on-click": "sh -c \"$HOME/.config/waybar/menu_main.sh toggle; pkill -RTMIN+11 waybar\""
  },

  "custom/menu-lock": {
    "format": "{}",
    "return-type": "json",
    "signal": 11,
    "interval": 1,
    "exec": "$HOME/.config/waybar/menu_buttons.sh lock",
    "on-click": "sh -c \"$HOME/.config/waybar/menu_action.sh lock; pkill -RTMIN+11 waybar\"",
    "tooltip": true,
    "tooltip-format": "Lås skjerm"
  },

  "custom/menu-reboot": {
    "format": "{}",
    "return-type": "json",
    "signal": 11,
    "interval": 1,
    "exec": "$HOME/.config/waybar/menu_buttons.sh reboot",
    "on-click": "sh -c \"$HOME/.config/waybar/menu_action.sh reboot; pkill -RTMIN+11 waybar\"",
    "tooltip": true,
    "tooltip-format": "Omstart"
  },

  "custom/menu-poweroff": {
    "format": "{}",
    "return-type": "json",
    "signal": 11,
    "interval": 1,
    "exec": "$HOME/.config/waybar/menu_buttons.sh poweroff",
    "on-click": "sh -c \"$HOME/.config/waybar/menu_action.sh poweroff; pkill -RTMIN+11 waybar\"",
    "tooltip": true,
    "tooltip-format": "Slå av"
  },
  
  "network": {
    "format-wifi": "<span color='#00FFFF'> 󰤨 </span>{essid} ",
    "format-ethernet": "<span color='#7FFF00'>  </span>Wired ",
    "tooltip-format": "<span color='#FF1493'> 󰅧 </span>{bandwidthUpBytes}  <span color='#00BFFF'> 󰅢 </span>{bandwidthDownBytes}",
    "format-linked": "<span color='#FFA500'> 󱘖 </span>{ifname} (No IP) ",
    "format-disconnected": "<span color='#FF4040'>  </span>Disconnected ",
    "format-alt": "<span color='#00FFFF'> 󰤨 </span>{signalStrength}% ",
    "interval": 1
  },
  "battery": {
    "states": {
      "warning": 30,
      "critical": 15
    },
    "format": "<span color='#28CD41'> {icon} </span>{capacity}% ",
    "format-charging": "<span color='#28CD41'> 󱐋 </span>{capacity}% ",
	  "interval": 1,
    "format-icons": ["󰂎", "󰁼", "󰁿", "󰂁", "󰁹"],
    "tooltip": true
  },
  "pulseaudio": {
    "format": "<span color='#00FF7F'>{icon}</span>{volume}% ",
    "format-muted": "<span color='#FF4040'> 󰖁 </span>0% ",
    "format-icons": {
      "headphone": "<span color='#BF00FF'>  </span>",
      "hands-free": "<span color='#BF00FF'>  </span>",
      "headset": "<span color='#BF00FF'>  </span>",
      "phone": "<span color='#00FFFF'>  </span>",
      "portable": "<span color='#00FFFF'>  </span>",
      "car": "<span color='#FFA500'>  </span>",
      "default": [
        "<span color='#808080'>  </span>",
        "<span color='#FFFF66'>  </span>",
        "<span color='#00FF7F'>  </span>"
      ]
    },
    "on-click-right": "pavucontrol -t 3",
    "on-click": "sh -c 'wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q \"\\[MUTED\\]\" && wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 || wpctl set-mute @DEFAULT_AUDIO_SINK@ 1'",
    "scroll-step": 5,
    "on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
    "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    "tooltip": true,
    "tooltip-format": "Current volume: {volume}%"
  },
  "custom/mic": {
    "format": "{}",
    "return-type": "json",
    "states": { "muted": 1, "normal": 101 },
    "interval": 1,
    "signal": 8,
    "exec": "$HOME/.config/waybar/mic3.sh",
    "on-click": "sh -c \"$HOME/.config/waybar/mic_ctl.sh toggle; pkill -RTMIN+8 waybar\"",
    "on-click-right": "pavucontrol -t 4",
    "on-scroll-up": "sh -c \"$HOME/.config/waybar/mic_ctl.sh up; pkill -RTMIN+8 waybar\"",
    "on-scroll-down": "sh -c \"$HOME/.config/waybar/mic_ctl.sh down; pkill -RTMIN+8 waybar\"",
    "tooltip": true,
    "tooltip-format": "Microphone volume"
  },
  "memory": {
    "format": "<span color='#8A2BE2'>    </span>{used:0.1f}G/{total:0.1f}G ",
    "tooltip": true,
    "tooltip-format": "Memory used: {used:0.2f}G/{total:0.2f}G",
    "on-click": "sh -c \"hyprctl dispatch exec 'alacritty -e btop'\""
  },
  "cpu": {
    "format": "<span color='#FF9F0A'>    </span>{usage}% ",
    "tooltip": true,
    "on-click": "sh -c \"hyprctl dispatch exec 'alacritty -e btop'\""
  },
  "clock": {
    "interval": 1,
    "timezone": "Europe/Oslo",
    "format": "<span color='#BF00FF'>  </span>{:%H:%M:%S} ",
    "tooltip": true,
    "tooltip-format": "{:%A, %B %d, %Y}"
  },
  "tray": {
    "icon-size": 20,
    "spacing": 6
  },
  "backlight": {
    "device": "intel_backlight",
    "format": "<span color='#FFD700'>{icon}</span>{percent}% ",
    "tooltip": true,
    "tooltip-format": "Screen brightness: {percent}%",
    "format-icons": [
      "<span color='#696969'> 󰃞 </span>",  // 暗 - 深灰
      "<span color='#A9A9A9'> 󰃝 </span>",  // 中 - 灰
      "<span color='#FFFF66'> 󰃟 </span>",  // 亮 - 柠檬黄
      "<span color='#FFD700'> 󰃠 </span>"   // 最亮 - 金色
    ]
  },
  "bluetooth": {
    "format": "",
    "format-off": "",
    "format-disabled": "",
    "format-connected": "<span color='#00BFFF'>  </span>{device_alias} ",
    "format-connected-battery": "<span color='#00BFFF'>  </span>{device_alias}{device_battery_percentage}% ",
    "on-click": "blueman-manager",
    "tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
    "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
    "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
    "tooltip-format-enumerate-connected-battery": "{device_alias}\t{device_address}\t{device_battery_percentage}%"
  }
}


    '';

    # mic status helper script
    home.file.".config/waybar/mic.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

# Fast path: parse Sources and pick first non-monitor; print and exit
mapfile -t lines < <(wpctl status | awk '
  BEGIN{s=0}
  /^Sources:/ {s=1; next}
  s && /^[^[:space:]].*:/ {s=0}
  s {print}
')

pick_id_fast=""
for line in "''${lines[@]}"; do
  id=$(sed -n 's/.*[[:space:]]\([0-9]\+\)\..*/\1/p' <<<"$line" | head -n1)
  [[ -z "$id" ]] && continue
  if grep -qi 'monitor' <<<"$line"; then
    continue
  fi
  pick_id_fast="$id"
  break
done

if [[ -n "''${pick_id_fast}" ]]; then
  out=$(wpctl get-volume "$pick_id_fast" 2>/dev/null || true)
  if [[ -n "''${out}" ]]; then
    vol=$(awk '{print int($2*100+0.5)}' <<<"$out" 2>/dev/null || echo 0)
    if grep -q '\\[MUTED\\]' <<<"$out"; then
      echo "<span color='#FF4040'>  </span>0% "
    else
      echo "<span color='#FF69B4'>  </span>$vol% "
    fi
    exit 0
  fi
fi

# Fast path: pick first non-monitor Source from `wpctl status`
mapfile -t lines < <(wpctl status | awk '/Sources:/{s=1;next} /Sinks:/{s=0} s')

pick_id=""
for line in "''${lines[@]}"; do
  id=$(sed -n 's/.*[[:space:]]\([0-9]\+\)\..*/\1/p' <<<"$line" | head -n1)
  [[ -z "$id" ]] && continue
  if grep -qi 'monitor' <<<"$line"; then
    continue
  fi
  pick_id="$id"
  break
done

if [[ -n "''${pick_id}" ]]; then
  out=$(wpctl get-volume "$pick_id" 2>/dev/null || true)
  if [[ -n "''${out}" ]]; then
    vol=$(awk '{print int($2*100+0.5)}' <<<"$out" 2>/dev/null || echo 0)
    if grep -q '\\[MUTED\\]' <<<"$out"; then
      echo "<span color='#FF4040'>  </span>0% "
    else
      echo "<span color='#FF69B4'>  </span>$vol% "
    fi
    exit 0
  fi
fi

# Determine a real microphone source (exclude monitor sources). If none, we'll hide.
MIC_ID=""
default_id=$(wpctl status | awk '/Sources:/{s=1;next} /Sinks:/{s=0} s && /^\s*\*/ {gsub("[^0-9]","",$2); print $2; exit}')

is_real_source() {
  local id="$1"
  local cls
  cls=$(pw-cli info "$id" 2>/dev/null | awk -F ' = ' '/media.class/ {gsub(/\"/,"",$2); print $2; exit}') || true
  [[ "$cls" == "Audio/Source" ]]
}

if [[ -n "''${default_id:-}" ]] && is_real_source "$default_id"; then
  MIC_ID="$default_id"
else
  MIC_ID=$(pw-cli ls Node 2>/dev/null | awk '
    /^id [0-9]+/ {id=$2}
    /media.class = "Audio\/Source"/ {print id; exit}
  ') || true
fi

if [[ -z "''${MIC_ID:-}" ]]; then
  # No real microphone -> hide
  exit 0
fi

out=$(wpctl get-volume "''${MIC_ID:-@DEFAULT_AUDIO_SOURCE@}" 2>/dev/null || true)
if [[ -z "$out" ]]; then
  # No microphone source available -> hide module by printing nothing
  exit 0
fi

vol=$(awk '{print int($2*100+0.5)}' <<<"$out" 2>/dev/null || echo 0)
if grep -q '\[MUTED\]' <<<"$out"; then
  echo "<span color='#FF4040'>  </span>0% "
else
  echo "<span color='#FF69B4'>  </span>$vol% "
fi
'';
    };

    # mic control helper (adjusts only real microphone sources via wpctl)
    home.file.".config/waybar/mic_ctl.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

cmd=""
if [ $# -ge 1 ]; then
  cmd="$1"
fi

# Try to resolve numeric default source id to avoid misrouting
id=$(wpctl status | awk '/Sources:/{s=1;next} /Sinks:/{s=0} s && /^\s*\*/ {print $2; exit}' | sed 's/[^0-9]//g')
if [ -z "$id" ]; then
  id='@DEFAULT_AUDIO_SOURCE@'
fi

# Ensure we control a real microphone (Audio/Source), not a monitor
is_real_source() {
  local nid="$1"
  local cls
  cls=$(wpctl inspect "$nid" 2>/dev/null | sed -n 's/.*media.class = \"\([^\"]*\)\".*/\1/p' | head -n1) || true
  [ -n "$cls" ] && [[ "$cls" == Audio/Source* ]] && [[ "$cls" != *Monitor* ]]
}

if ! is_real_source "$id"; then
  id=$(pw-cli ls Node 2>/dev/null | awk '
    /^id [0-9]+/ {id=$2}
    /media.class = "Audio\/Source"/ {print id; exit}
  ') || true
fi

if [ -z "$id" ]; then
  # No real mic available; nothing to control
  exit 0
fi

case "$cmd" in
  toggle)
    wpctl set-mute "$id" toggle ;;
  up)
    wpctl set-volume "$id" 5%+ ;;
  down)
    wpctl set-volume "$id" 5%- ;;
  *)
    echo "Usage: $0 {toggle|up|down}" >&2
    exit 1 ;;
esac
'';
    };

    home.file.".config/waybar/mic2.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

get_class() {
  wpctl inspect "$1" 2>/dev/null | sed -n 's/.*media.class = \"\([^\"]*\)\".*/\1/p' | head -n1
}

default_id=$(wpctl status | awk '/Sources:/{s=1;next} s && /^\s*\*/ {gsub("[^0-9]","",$2); print $2; exit}')
ids=$(wpctl status | awk '/Sources:/{s=1;next} s && /^[[:space:]]*[0-9]+\./ {gsub("[^0-9]","",$1); print $1}')

pick_id=""

if [[ -n "''${default_id:-}" ]]; then
  cls=$(get_class "$default_id" || true)
  if [[ -n "''${cls}" ]] && [[ "''${cls}" == Audio/Source* ]] && [[ "''${cls}" != *Monitor* ]]; then
    pick_id="$default_id"
  fi
fi

if [[ -z "''${pick_id}" ]]; then
  while read -r id; do
    [[ -z "''${id}" ]] && continue
    cls=$(get_class "$id" || true)
    if [[ -n "''${cls}" ]] && [[ "''${cls}" == Audio/Source* ]] && [[ "''${cls}" != *Monitor* ]]; then
      pick_id="$id"
      break
    fi
  done <<< "''${ids}"
fi

if [[ -z "''${pick_id}" ]]; then
  exit 0
fi

out=$(wpctl get-volume "$pick_id" 2>/dev/null || true)
if [[ -z "''${out}" ]]; then
  exit 0
fi

vol=$(awk '{print int($2*100+0.5)}' <<<"$out" 2>/dev/null || echo 0)
if grep -q '\\[MUTED\\]' <<<"$out"; then
  echo "<span color='#FF4040'>  ''${vol}% </span>"
else
  echo "<span color='#FF69B4'>  </span>''${vol}% "
fi
'';
    };

    # Simple and robust mic status script using default source only
    home.file.".config/waybar/mic3.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -u

export LC_ALL=C

# Check class of default source; hide if not a real mic
cls=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | sed -n 's/.*media.class = \"\([^\"]*\)\".*/\1/p' | head -n1)
[ -z "''${cls:-}" ] && exit 0
case "''${cls}" in
  *Monitor*|Audio/Source\ Output|Audio/Sink*) exit 0 ;;
esac

# Get volume of default source and detect mute reliably
out=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)
[ -z "$out" ] && exit 0
vol=$(awk '{print int($2*100+0.5)}' <<<"$out" 2>/dev/null || echo 0)

muted=0
if grep -qi '\\[MUTED\\]' <<<"$out"; then
  muted=1
else
  if wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -Eqi '(^|[[:space:]])mute[[:space:]]*=[[:space:]]*true'; then
    muted=1
  fi
fi

if [ "$muted" -eq 1 ]; then
  # Set class and a small non-zero percentage so the `states.muted` threshold applies
  printf '{"text":"%s","class":"%s","percentage":%d}\n' " ''${vol}%" "muted" 1
else
  # Mark as normal so CSS applies the semi-transparent background
  # Keep percentage below muted threshold to avoid unintended state class
  printf '{"text":"%s","class":"%s","percentage":%d}\n' " ''${vol}%" "normal" 0
fi
'';
    };

    # Waybar click-to-open menu popup under cursor (rofi)
    home.file.".config/waybar/menu_popup.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

# Basic menu entries: icon + label (reuse existing glyphs)
MENU_ITEMS=$(cat <<'EOF'
  Lås skjerm
  Omstart
  Slå av
EOF
)

# Try to get cursor position (x y) from Hyprland
get_cursor_pos() {
  local cx cy line
  if line=$(hyprctl cursorpos 2>/dev/null | head -n1); then
    # Extract first two integers found
    cx=$(sed -n 's/[^0-9]*\([0-9]\+\)[^0-9]\+\([0-9]\+\).*/\1/p' <<<"$line")
    cy=$(sed -n 's/[^0-9]*\([0-9]\+\)[^0-9]\+\([0-9]\+\).*/\2/p' <<<"$line")
    if [[ -n "$cx" && -n "$cy" ]]; then
      printf '%s %s\n' "$cx" "$cy"
      return 0
    fi
  fi
  # Fallback to safe defaults if detection fails
  printf '200 40\n'
}

read -r CUR_X CUR_Y < <(get_cursor_pos)

# Popup geometry
WIDTH=240
ROW_H=36
COUNT=3
HEIGHT=$((COUNT * ROW_H + 10))

# Place slightly below click point
POS_X=$(( CUR_X - WIDTH / 2 ))
POS_Y=$(( CUR_Y + 28 ))

choice=$(printf '%s\n' "$MENU_ITEMS" \
  | rofi -dmenu \
          -i \
          -p "" \
          -theme-str "window { width: ''${WIDTH}px; location: north; anchor: north; x-offset: ''${POS_X}; y-offset: ''${POS_Y}; } listview { lines: ''${COUNT}; }")

# Exit if nothing selected
[[ -n "$choice" ]] || exit 0

case "''${choice%% *}" in
  )
    hyprctl dispatch exec hyprlock >/dev/null 2>&1 & ;;
  )
    hyprctl dispatch exec "systemctl reboot" >/dev/null 2>&1 & ;;
  )
    hyprctl dispatch exec "systemctl poweroff" >/dev/null 2>&1 & ;;
  *)
    : ;;  # ignore
esac
'';
    };

    # Inline power menu: main toggle button (prints JSON)
    home.file.".config/waybar/menu_main.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

# Keep state in the runtime dir so it resets per login session
RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_FILE="$RUNTIME_DIR/waybar_power_menu_open"
mkdir -p "$(dirname "$STATE_FILE")"

# Detect Waybar PID reliably by walking up the PPID chain
get_waybar_pid() {
  local p name args np
  p="$PPID"
  for _ in 1 2 3 4 5 6 7 8; do
    name=$(ps -o comm= -p "$p" 2>/dev/null | tr -d ' ' || true)
    if [[ "$name" == "waybar" || "$name" == "waybar-wrapped" ]]; then
      printf '%s\n' "$p"; return 0
    fi
    # Fallback: check full args in case of wrapper
    args=$(ps -o args= -p "$p" 2>/dev/null || true)
    if grep -Eq '(^|/)(waybar|waybar-wrapped)(\s|$)' <<<"$args"; then
      printf '%s\n' "$p"; return 0
    fi
    np=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ' || true)
    [[ -z "$np" || "$np" == "$p" ]] && break
    p="$np"
  done
  # Last resort: pick a running waybar pid if any
  p=$(pgrep -n -x waybar 2>/dev/null || true)
  [[ -n "$p" ]] && { printf '%s\n' "$p"; return 0; }
  p=$(pgrep -n waybar 2>/dev/null || true)
  [[ -n "$p" ]] && { printf '%s\n' "$p"; return 0; }
  printf '0\n'
}
WAYBAR_PID=$(get_waybar_pid)

case "''${1:-status}" in
  toggle)
    if [[ -f "$STATE_FILE" ]]; then
      rm -f "$STATE_FILE"
    else
      : > "$STATE_FILE"
    fi
    exit 0 ;;
  open)
    : > "$STATE_FILE" ; exit 0 ;;
  close)
    rm -f "$STATE_FILE" 2>/dev/null || true ; exit 0 ;;
  *) : ;;
esac

if [[ -f "$STATE_FILE" ]]; then
  wb_age=$(ps -o etimes= -p "$WAYBAR_PID" 2>/dev/null | tr -d ' ' || true)
  if [[ -n "''${wb_age:-}" && "''${wb_age:-0}" -gt 0 ]]; then
    now=$(date +%s)
    mtime=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo "$now")
    if (( now - mtime > wb_age )); then
      rm -f "$STATE_FILE" 2>/dev/null || true
    fi
  fi
fi

if [[ -f "$STATE_FILE" ]]; then
  # When open, show a close icon and mark as open for CSS styling
  printf '{"text":"%s","class":"%s"}\n' "" "open"
else
  printf '{"text":"%s"}\n' ""
fi
'';
    };

    # Inline power menu: button render helper (prints JSON for each icon or hides when closed)
    home.file.".config/waybar/menu_buttons.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_FILE="$RUNTIME_DIR/waybar_power_menu_open"
kind="''${1:-lock}"

# Hide if menu is closed
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

case "$kind" in
  lock) icon="" ;;
  reboot) icon="" ;;
  poweroff|power) icon="" ;;
  *) icon="" ;;
esac

if [[ -n "$icon" ]]; then
  printf '{"text":"%s"}\n' "$icon"
fi
'';
    };

    # Inline power menu: actions for each icon
    home.file.".config/waybar/menu_action.sh" = {
      executable = true;
      text = ''
#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_FILE="$RUNTIME_DIR/waybar_power_menu_open"
action="''${1:-}"

case "$action" in
  lock)
    hyprctl dispatch exec hyprlock >/dev/null 2>&1 & ;;
  reboot)
    hyprctl dispatch exec "systemctl reboot" >/dev/null 2>&1 & ;;
  poweroff|power)
    hyprctl dispatch exec "systemctl poweroff" >/dev/null 2>&1 & ;;
  *) ;;
esac

# Close the menu after an action
rm -f "$STATE_FILE" 2>/dev/null || true
'';
    };

}
