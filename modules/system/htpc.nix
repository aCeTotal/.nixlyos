{ pkgs, pkgs-stable, lib, config, ... }:

let
  opts = import ../core/nixlytile_options.nix;
  htpcEnabled = (opts.nixlytileMode or 1) == 2;
in
lib.mkIf htpcEnabled {

  # ─────────────────────────────────────────
  #   System packages (retroarch only — mpv via home-manager)
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
    ]);

  # Note: Intel Arc VAAPI/Vulkan stack (intel-media-driver, vpl-gpu-rt,
  # iHD driver env) lives in modules/core/gpu/intel.nix — mpv hwdec on
  # A770 uses that already.

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

    # ─────────────────────────────────────────
    #   mpv — ultra-smooth 4K60 on Intel Arc A770
    # ─────────────────────────────────────────
    # gpu-next + Vulkan + VAAPI hwdec on Arc. display-resample +
    # interpolation (tscale=oversample) eliminates 24/25/30p judder
    # against the 60Hz panel. EWA Lanczos sharp upscale to 4K.
    # Huge demuxer cache eats local-server files whole for zero stalls.
    # HDR settings are no-ops on SDR displays.
    programs.mpv = {
      enable = true;

      config = {
        # ── Output: Vulkan + gpu-next on Arc A770 ──
        vo = "gpu-next";
        gpu-api = "vulkan";
        gpu-context = "auto";
        hwdec = "vaapi";
        vd-lavc-dr = "yes";
        hwdec-codecs = "all";
        vulkan-swap-mode = "fifo";
        swapchain-depth = 6;
        gpu-shader-cache-dir = "~/.cache/mpv/shaders";

        # ── Display: fullscreen 4K@60 on TV ──
        fullscreen = "yes";
        keep-open = "yes";
        cursor-autohide = 500;
        display-fps-override = 60;

        # ── Frame timing: ultra-smooth motion at 60Hz ──
        # display-resample retimes audio to display refresh.
        # interpolation + tscale=oversample fixes 24->60 judder
        # (oversample = non-blurry phase-blend, ideal for 24/25/30 -> 60).
        video-sync = "display-resample";
        interpolation = "yes";
        tscale = "oversample";
        framedrop = "vo";
        video-latency-hacks = "no";
        hr-seek-framedrop = "no";

        # ── Scaling: high-quality upscale to 4K on Arc ──
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossoft";
        dscale = "mitchell";
        correct-downscaling = "yes";
        linear-downscaling = "yes";
        sigmoid-upscaling = "yes";
        dither-depth = "auto";
        deband = "yes";
        deband-iterations = 2;
        deband-threshold = 35;
        deband-range = 16;
        deband-grain = 4;

        # ── HDR passthrough (no-op on SDR TV) ──
        target-colorspace-hint = "yes";
        target-peak = "auto";
        hdr-compute-peak = "yes";
        tone-mapping = "bt.2446a";
        gamut-mapping-mode = "perceptual";

        # ── Audio: bit-perfect passthrough to TV/AVR ──
        audio-channels = "auto";
        audio-exclusive = "yes";
        audio-spdif = "ac3,dts,eac3,truehd";

        # ── Cache: fat local-server buffer, never stall ──
        # 4 GiB forward + 512 MiB back = minutes of 4K readahead,
        # instant seek-back. Local NFS/SMB fills this in seconds.
        cache = "yes";
        cache-secs = 600;
        cache-pause = "yes";
        cache-pause-wait = 1;
        cache-pause-initial = "no";
        cache-on-disk = "no";
        demuxer-max-bytes = "4GiB";
        demuxer-max-back-bytes = "512MiB";
        demuxer-readahead-secs = 600;
        demuxer-seekable-cache = "yes";
        demuxer-hysteresis-secs = 30;
        stream-buffer-size = "64MiB";
        network-timeout = 60;
        prefetch-playlist = "yes";

        # ── Subs / audio language priority ──
        sub-auto = "fuzzy";
        slang = "no,nob,en,eng";
        alang = "no,nob,en,eng";

        # ── Screenshots ──
        screenshot-format = "png";
        screenshot-directory = "~/Pictures/mpv";
      };
    };
  };
}
