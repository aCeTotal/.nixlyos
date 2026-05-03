{ pkgs, lib, ... }:

{
  # ═══════════════════════════════════════════════════════════════════
  # RetroArch — full installation with cores + XMB theme + controllers
  # ═══════════════════════════════════════════════════════════════════
  # Cores: NES, SNES, N64 (+ a few common extras for completeness).
  # Controllers: USB + Bluetooth picked up from gaming.nix (xpadneo,
  # xone, bluez, udev). Joypad driver = udev → hot-plug friendly.
  # Config written via home-manager activation; user can still tweak
  # in-app, changes persist until next nixos-rebuild.
  # ═══════════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    (retroarch.withCores (cores: [
      # N64
      cores.mupen64plus
      cores.parallel-n64

      # NES
      cores.nestopia
      cores.fceumm

      # SNES
      cores.snes9x
      cores.bsnes

      # Bonus retro coverage (no extra setup needed)
      cores.genesis-plus-gx       # Mega Drive / SMS / Game Gear
      cores.gambatte              # GB / GBC
      cores.mgba                  # GBA
      cores.beetle-psx-hw         # PlayStation 1 (Vulkan/HW)
    ]))

    retroarch-assets           # XMB icons, fonts, menu assets
    retroarch-joypad-autoconfig
  ];

  # XMB needs OpenGL + assets. udev rules + bluetooth already wired in
  # gaming.nix — no duplication here.

  home-manager.users.total = { lib, ... }: {
    home.activation.retroarchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      RA_CFG_DIR="$HOME/.config/retroarch"
      mkdir -p "$RA_CFG_DIR"
      mkdir -p "$RA_CFG_DIR/cores"
      mkdir -p "$RA_CFG_DIR/system"
      mkdir -p "$RA_CFG_DIR/saves"
      mkdir -p "$RA_CFG_DIR/states"
      mkdir -p "$RA_CFG_DIR/screenshots"
      mkdir -p "$RA_CFG_DIR/playlists"
      mkdir -p "$RA_CFG_DIR/thumbnails"

      cat > "$RA_CFG_DIR/retroarch.cfg" << 'RACFG'
      # ── Menu / theme ────────────────────────────────────
      menu_driver = "xmb"
      # Icon pack: 0=monochrome (most popular & complete coverage of cores)
      # In-app: Settings → User Interface → Appearance → Icon Theme to switch
      # to systematic / retrosystem / dot-art / pixel / flatui / automatic etc.
      menu_xmb_theme = "0"
      menu_xmb_menu_color_theme = "1"
      menu_xmb_shadows_enable = "true"
      menu_xmb_ribbon_enable = "1"
      menu_horizontal_animation = "true"
      menu_show_load_core = "true"
      menu_show_load_content = "true"
      menu_show_online_updater = "true"
      menu_show_core_updater = "true"
      menu_enable_widgets = "true"
      menu_widget_scale_auto = "true"
      rgui_show_start_screen = "false"
      quick_menu_show_save_load_state = "true"
      quick_menu_show_take_screenshot = "true"

      # Per-system XMB wallpapers (NES/SNES/N64/etc backgrounds).
      menu_dynamic_wallpaper_enable = "true"
      dynamic_wallpapers_directory = "${pkgs.retroarch-assets}/share/retroarch/assets/wallpapers"

      # Thumbnail display in playlists/XMB (boxart on right, snap on left).
      menu_thumbnails = "3"
      menu_left_thumbnails = "2"
      menu_rgui_thumbnail_downscaler = "1"
      playlist_show_sublabels = "true"

      # XMB asset paths (provided by retroarch-assets)
      assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets"
      xmb_font = ""

      # ── Video ───────────────────────────────────────────
      video_driver = "vulkan"
      video_fullscreen = "true"
      video_windowed_fullscreen = "true"
      video_vsync = "true"
      video_threaded = "true"
      video_smooth = "true"
      video_scale_integer = "false"
      video_aspect_ratio_auto = "true"

      # ── Audio ───────────────────────────────────────────
      audio_driver = "pipewire"
      audio_enable = "true"
      audio_sync = "true"
      audio_volume = "0.0"

      # ── Input / controllers ─────────────────────────────
      input_driver = "udev"
      input_joypad_driver = "udev"
      input_autodetect_enable = "true"
      input_auto_remaps_enable = "true"
      input_max_users = "4"
      input_menu_toggle_gamepad_combo = "4"   # L3 + R3 → menu
      input_overlay_enable = "false"
      input_bluetooth_driver = "bluez"

      # Autoconfig profiles directory (xpad, dualshock, etc.)
      joypad_autoconfig_dir = "${pkgs.retroarch-joypad-autoconfig}/share/libretro/autoconfig"

      # ── Core / content paths ────────────────────────────
      libretro_directory = "$HOME/.config/retroarch/cores"
      libretro_info_path = "$HOME/.config/retroarch/cores"
      system_directory = "$HOME/.config/retroarch/system"
      savefile_directory = "$HOME/.config/retroarch/saves"
      savestate_directory = "$HOME/.config/retroarch/states"
      screenshot_directory = "$HOME/.config/retroarch/screenshots"
      playlist_directory = "$HOME/.config/retroarch/playlists"
      thumbnails_directory = "$HOME/.config/retroarch/thumbnails"

      # ── Online updater (icon packs, thumbnail packs, cores) ─────
      # Lets the in-app updater fetch additional XMB icon themes and
      # the libretro-thumbnails packs (Nintendo - NES, SNES, N64, …)
      # from the official buildbot. Trigger: Main Menu → Online Updater.
      network_on_demand_thumbnails = "true"
      core_updater_buildbot_url = "https://buildbot.libretro.com/nightly/linux/x86_64/latest/"
      core_updater_buildbot_assets_url = "https://buildbot.libretro.com/assets/"
      core_updater_auto_extract_archive = "true"
      core_updater_show_experimental_cores = "false"
      menu_show_core_updater = "true"
      automatically_add_content_to_playlist = "true"

      # ── Misc ────────────────────────────────────────────
      pause_nonactive = "false"
      check_firmware_before_loading = "false"
      auto_screenshot_filename = "true"
      savestate_auto_save = "true"
      savestate_auto_load = "true"
      config_save_on_exit = "true"
      RACFG
    '';
  };
}
