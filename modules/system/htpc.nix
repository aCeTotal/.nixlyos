{ pkgs, pkgs-stable, lib, config, ... }:

let
  opts = import ../core/nixlytile_options.nix;
  htpcEnabled = (opts.nixlytileMode or 1) == 2;
in
lib.mkIf htpcEnabled {

  # ─────────────────────────────────────────
  #   Jellyfin media server
  # ─────────────────────────────────────────
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Server-side theme: better-jellyfin-ui (tromoSM) via branding.xml.
  # Regenerated on every jellyfin start — stays declarative even if someone
  # edits Branding in the dashboard.
  systemd.services.jellyfin.preStart = ''
    mkdir -p /var/lib/jellyfin/config
    cat > /var/lib/jellyfin/config/branding.xml <<'EOF'
    <?xml version="1.0" encoding="utf-8"?>
    <BrandingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <LoginDisclaimer></LoginDisclaimer>
      <CustomCss>@import url("https://cdn.jsdelivr.net/gh/tromoSM/better-jellyfin-ui@main/theme.css");</CustomCss>
      <SplashscreenEnabled>true</SplashscreenEnabled>
    </BrandingOptions>
    EOF
    chown jellyfin:jellyfin /var/lib/jellyfin/config/branding.xml
    chmod 0644 /var/lib/jellyfin/config/branding.xml
  '';

  # ─────────────────────────────────────────
  #   System packages (retroarch + jellyfin client)
  # ─────────────────────────────────────────
  environment.systemPackages =
    (with pkgs-stable; [
      (retroarch.withCores (cores: with cores; [
        nestopia
        snes9x
        bsnes
        genesis-plus-gx
        mupen64plus
        beetle-psx-hw
        pcsx-rearmed
        mgba
        gambatte
        beetle-saturn
        flycast
        melonds
        mame
        stella
        ppsspp
        fbneo
      ]))
      retroarch-assets
      retroarch-joypad-autoconfig
      libretro-shaders-slang
    ])
    ++ (with pkgs; [
      jellyfin-media-player
    ]);

  # ─────────────────────────────────────────
  #   Home-manager configs for the user
  # ─────────────────────────────────────────
  home-manager.users.total = { pkgs, ... }: {

    # RetroArch main config — XMB (PS3-style) menu with neoactive icon pack,
    # 4K fullscreen Vulkan tuned for Intel Arc, bilinear pixel smoothing,
    # pipewire audio, gamepad menu toggle (L3+R3), auto save/load states.
    xdg.configFile."retroarch/retroarch.cfg".text = ''
      # ── Video: Vulkan on Intel Arc, 4K fullscreen ──
      video_driver = "vulkan"
      video_fullscreen = "true"
      video_windowed_fullscreen = "false"
      video_fullscreen_x = "3840"
      video_fullscreen_y = "2160"
      video_vsync = "true"
      video_adaptive_vsync = "true"
      video_hard_sync = "false"
      video_max_swapchain_images = "3"
      video_threaded = "true"
      video_frame_delay = "0"
      video_frame_delay_auto = "true"
      video_gpu_screenshot = "true"
      video_shared_context = "true"

      # ── Scaling: fill 4K, preserve PAR, smooth pixels ──
      video_aspect_ratio_auto = "true"
      aspect_ratio_index = "22"
      video_scale_integer = "false"
      video_smooth = "true"
      video_ctx_scaling = "true"
      video_force_aspect = "true"

      # ── Default shader for smoother pixel art on all cores ──
      # xBR Lv2 edge-smoothing upscaler (flip off per-core if perf drops)
      video_shader_enable = "true"
      video_shader_dir = "${pkgs-stable.libretro-shaders-slang}/share/libretro/shaders/shaders_slang"
      video_shader = "${pkgs-stable.libretro-shaders-slang}/share/libretro/shaders/shaders_slang/edge-smoothing/xbr/xbr-lv2.slangp"

      # ── Audio ──
      audio_driver = "pipewire"
      audio_enable = "true"
      audio_sync = "true"
      audio_volume = "0.0"
      audio_latency = "32"

      # ── Menu: XMB (PS3-style) with neoactive icons, electric blue ──
      menu_driver = "xmb"
      xmb_theme = "4"
      xmb_menu_color_theme = "4"
      menu_show_load_content = "true"
      menu_show_quit_retroarch = "true"
      menu_show_restart_retroarch = "true"
      menu_show_online_updater = "true"
      menu_show_core_updater = "true"
      quit_press_twice = "false"
      menu_enable_widgets = "true"
      menu_widget_scale_auto = "true"

      # ── Input ──
      input_max_users = "4"
      input_autodetect_enable = "true"
      input_joypad_driver = "sdl2"
      input_menu_toggle_gamepad_combo = "2"

      # ── Savestates ──
      savestate_auto_save = "true"
      savestate_auto_load = "true"
      savestate_thumbnail_enable = "true"

      # ── Misc ──
      pause_nonactive = "false"
      fps_show = "false"

      # ── Asset / autoconfig paths ──
      assets_directory = "${pkgs-stable.retroarch-assets}/share/retroarch/assets"
      joypad_autoconfig_dir = "${pkgs-stable.retroarch-joypad-autoconfig}/share/libretro/autoconfig"
    '';

    # Jellyfin Media Player — fullscreen HTPC defaults.
    # userWebClient + webClient make JMP skip the server-chooser
    # wizard on first launch and load jellyfin.aceclan.no directly.
    xdg.configFile."jellyfinmediaplayer/jellyfinmediaplayer.conf".text = ''
      [main]
      fullscreen=true
      alwaysOnTop=false
      disableOsScreensaver=true
      userWebClient=true
      webClient=https://jellyfin.aceclan.no/web/index.html

      [connections]
      defaultServer=https://jellyfin.aceclan.no/
      skipServerSelection=true

      [video]
      hardwareDecoding=true
      useRefreshRateSwitching=true
      useDisplayFpsFromOs=true

      [audio]
      passthrough.ac3=true
      passthrough.dts=true
      passthrough.eac3=true
      passthrough.truehd=true
    '';

    # mpv backend for Jellyfin Media Player — HDR passthrough +
    # display-locked interpolation + Intel Arc hwdec. gpu-next is the
    # only mpv output that supports HDR and interpolation together.
    home.file.".local/share/jellyfinmediaplayer/mpv/mpv.conf".text = ''
      # ── Output: Vulkan, Intel Arc, Wayland ──
      vo=gpu-next
      gpu-api=vulkan
      gpu-context=auto
      hwdec=auto-safe
      vd-lavc-dr=yes

      # ── HDR passthrough ──
      # target-colorspace-hint signals HDR metadata to the Wayland
      # compositor (nixlytile) so the display enters HDR mode.
      # target-peak=auto reads the display's EDID peak luminance.
      target-colorspace-hint=yes
      target-peak=auto
      hdr-compute-peak=yes
      tone-mapping=bt.2446a
      gamut-mapping-mode=perceptual

      # ── Frame timing: refresh-rate locked, interpolated (HDR-safe
      # with gpu-next) ──
      video-sync=display-resample
      interpolation=yes
      tscale=oversample
      framedrop=vo
      video-latency-hacks=no

      # ── Scaling: efficient on Arc, high quality upscale to 4K ──
      scale=ewa_lanczossharp
      cscale=ewa_lanczossoft
      dscale=mitchell
      correct-downscaling=yes
      linear-downscaling=yes
      sigmoid-upscaling=yes
      dither-depth=auto
      deband=no

      # ── Audio: bit-perfect passthrough to AVR/TV ──
      audio-channels=auto
      audio-exclusive=yes
      audio-spdif=ac3,dts,eac3,truehd

      # ── Cache for smooth network playback ──
      cache=yes
      demuxer-max-bytes=512MiB
      demuxer-readahead-secs=30
    '';
  };
}
