{ config, lib, pkgs, ... }:

{
  services.dunst = {
    enable = true;
    settings = {
      # Global defaults
      global = {
        # Place notifications at the right edge (top-right by default)
        origin = "top-right";
        # Offset from screen edges: horizontal x vertical (px)
        offset = "0x50"; # move 50px down

        # Modern look & readability
        font = "Sans 12";
        padding = 12;
        horizontal_padding = 16;
        frame_width = 0;            # no hard border; cleaner look
        corner_radius = 10;         # rounded corners
        separator_height = 0;       # hide separator line
        separator_color = "frame"; # if shown, use frame color
        alignment = "left";
        word_wrap = true;
        ellipsize = "end";
        ignore_newline = true;
        indicate_hidden = true;
        transparency = 12;          # X11 only; Wayland handled via Hyprland layerrule
        follow = "none";            # don’t move with focus
        browser = "xdg-open";
        format = "<b>%s</b>\n%b";
        show_age_threshold = 60;
        icon_position = "left";
        max_icon_size = 48;
      };

      # Timeouts per urgency. Dunst uses seconds (ints). Closest to 1.5s is 2s.
      urgency_low = {
        timeout = 2;
        background = "#0f1b35";
        foreground = "#dcdfe1";
        frame_color = "#2d3a58";
      };
      urgency_normal = {
        timeout = 2;
        background = "#0f1b35";
        foreground = "#dcdfe1";
        frame_color = "#2d3a58";
      };
      urgency_critical = {
        timeout = 0;
        background = "#3b0f12";
        foreground = "#ffffff";
        frame_color = "#ff5a5f";
      };
    };
  };
}
