{ ... }:

{
  config.home-manager.sharedModules = [
    ({ pkgs, ... }: {
      programs.mpv = {
        enable = true;
        package = pkgs.mpv;

        # ── Hovedconfig: smooth playback på alle skjermer ─────────
        # Nøkkelen til "no hikking":
        #   video-sync=display-resample → sync til skjermens refresh, resample audio
        #   interpolation=yes           → interpolere frames når refresh > fps
        #   tscale=oversample           → frame doubling for integer ratios uten tap
        # mpv auto-detekterer hvilken skjerm vinduet er på og bruker dens FPS.
        config = {
          # ── Video output (Nvidia + Wayland/Hyprland) ────────────
          # gpu-next + vulkan = beste kvalitet/ytelse på moderne hw
          # gpu-context auto-detekteres (waylandvk på Hyprland, x11vk på X11)
          vo = "gpu-next";
          gpu-api = "vulkan";
          hwdec = "auto-safe";
          hwdec-codecs = "all";

          # ── Display sync (KRITISK for smooth) ───────────────────
          video-sync = "display-resample";
          interpolation = true;
          tscale = "oversample";
          # video-latency-hacks gir lavere input-lag, ikke tap for video
          video-latency-hacks = true;

          # ── Skalering / kvalitet ────────────────────────────────
          profile = "high-quality";
          scale = "ewa_lanczossharp";
          cscale = "ewa_lanczossharp";
          dscale = "mitchell";
          dither-depth = "auto";
          deband = true;
          deband-iterations = 2;
          deband-threshold = 35;
          deband-range = 16;
          deband-grain = 4;

          # ── HDR (TV) ────────────────────────────────────────────
          target-colorspace-hint = true;
          # Tone-mapping for HDR-innhold på SDR-skjerm
          tone-mapping = "bt.2446a";
          hdr-compute-peak = true;

          # ── Audio ───────────────────────────────────────────────
          audio-channels = "auto-safe";
          audio-spdif = "ac3,dts,eac3,dts-hd,truehd";
          audio-exclusive = false;
          af = "scaletempo2";
          volume = 100;
          volume-max = 150;

          # ── Subtitles ───────────────────────────────────────────
          sub-auto = "fuzzy";
          sub-file-paths = "subs:subtitles:Subs";
          slang = "no,nob,nor,en,eng";
          alang = "no,nob,nor,jpn,en,eng";
          sub-font = "Noto Sans";
          sub-font-size = 42;
          sub-border-size = 2;
          sub-shadow-offset = 1;

          # ── Cache (smooth nettverks-streaming) ──────────────────
          cache = true;
          cache-secs = 60;
          demuxer-max-bytes = "512MiB";
          demuxer-max-back-bytes = "256MiB";
          demuxer-readahead-secs = 30;

          # ── Vindu / skjerm ──────────────────────────────────────
          keep-open = "yes";
          save-position-on-quit = true;
          watch-later-options-remove = "pause";
          screenshot-format = "png";
          screenshot-directory = "~/Pictures/mpv";

          # ── OSD ─────────────────────────────────────────────────
          osd-bar = true;
          osd-font = "JetBrainsMono Nerd Font";
          osd-font-size = 28;

          # ── YouTube / streaming ─────────────────────────────────
          ytdl-format = "bestvideo[height<=?2160][vcodec!=?vp9]+bestaudio/best";
          script-opts = "ytdl_hook-ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp";
        };

        # ── Profil-overrides (auto-aktiveres på match) ────────────
        profiles = {
          # Lavere refresh-skjermer (TV 60Hz med 24p innhold)
          # Brukes manuelt: mpv --profile=tv
          "tv" = {
            profile-desc = "TV / HTPC playback";
            fullscreen = true;
            interpolation = true;
            tscale = "oversample";
            video-sync = "display-resample";
            deband = true;
            tone-mapping = "bt.2446a";
            hdr-compute-peak = true;
          };

          # 4K / høy-bitrate
          "high-res" = {
            profile-desc = "auto profile for >=1440p";
            profile-cond = "(width or 0) >= 1440";
            scale = "ewa_lanczos";
            cscale = "ewa_lanczos";
            deband = false;
          };

          # Lav oppløsning oppskalering
          "low-res" = {
            profile-desc = "auto profile for <720p";
            profile-cond = "(width or 0) < 1280";
            scale = "ewa_lanczossharp";
            cscale = "ewa_lanczossharp";
            deband = true;
          };

          # Anime
          "anime" = {
            profile-desc = "Anime tuning";
            profile-cond = "string.match(p.filename, '%.[Aa]nime') ~= nil";
            deband = true;
            deband-iterations = 4;
            deband-grain = 24;
            scale = "ewa_lanczossharp";
            cscale = "mitchell";
          };
        };

        # ── Bindings ──────────────────────────────────────────────
        bindings = {
          # Navigasjon
          "RIGHT" = "seek 5";
          "LEFT" = "seek -5";
          "UP" = "seek 60";
          "DOWN" = "seek -60";
          "Shift+RIGHT" = "seek 30";
          "Shift+LEFT" = "seek -30";

          # Hastighet
          "[" = "multiply speed 0.9091";
          "]" = "multiply speed 1.1";
          "BS" = "set speed 1.0";

          # Volum
          "WHEEL_UP" = "add volume 5";
          "WHEEL_DOWN" = "add volume -5";
          "m" = "cycle mute";

          # Sub / audio
          "j" = "cycle sub";
          "J" = "cycle sub down";
          "#" = "cycle audio";

          # Diverse
          "f" = "cycle fullscreen";
          "TAB" = "cycle ontop";
          "i" = "script-binding stats/display-stats-toggle";
          "I" = "script-binding stats/display-stats";
          "p" = "cycle pause";
          "q" = "quit-watch-later";
          "Q" = "quit";

          # Profil-bytte
          "Ctrl+t" = "apply-profile tv";

          # Frame-stepping
          "." = "frame-step";
          "," = "frame-back-step";

          # Screenshot
          "s" = "screenshot";
          "S" = "screenshot video";
        };

        # ── Scripts ───────────────────────────────────────────────
        scripts = with pkgs.mpvScripts; [
          mpris            # MPRIS for media-keys / control center
          thumbfast        # Hurtig thumbnail-preview ved seeking
          autoload         # Auto-load neste fil i mappa
          uosc             # Moderne OSC/UI
          quality-menu     # YouTube quality picker
        ];
      };

      # mpv trenger yt-dlp for streaming
      home.packages = with pkgs; [
        yt-dlp
      ];
    })
  ];
}
