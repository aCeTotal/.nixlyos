{ pkgs, ... }:

let
  rusty-rain = pkgs.callPackage ../derivations/rusty-rain { };

  # Foot fullscreen med rusty-rain. app-id matcher niri window-rule.
  screensaver-start = pkgs.writeShellScript "screensaver-start" ''
    ${pkgs.procps}/bin/pgrep -x rusty-rain >/dev/null && exit 0
    exec ${pkgs.foot}/bin/foot \
      --app-id=rusty-rain-screensaver \
      --title=screensaver \
      --font="JetBrainsMono Nerd Font:size=14" \
      -- ${rusty-rain}/bin/rusty-rain
  '';

  # Drep rusty-rain og start hyprlock før kontroll gis tilbake.
  screensaver-stop = pkgs.writeShellScript "screensaver-stop" ''
    ${pkgs.procps}/bin/pkill -x rusty-rain || true
    ${pkgs.procps}/bin/pkill -f rusty-rain-screensaver || true
    ${pkgs.hyprlock}/bin/hyprlock --immediate &
  '';
in
{
  home.packages = [
    rusty-rain
    pkgs.hyprlock
    pkgs.swayidle
    pkgs.foot
  ];

  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle manager - rusty-rain screensaver + hyprlock";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w "
        + "timeout 300 ${screensaver-start} "
        + "resume ${screensaver-stop} "
        + "lock ${pkgs.hyprlock}/bin/hyprlock";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Hyprlock - moderne theme med blurred screenshot, stor klokke, dato.
  xdg.configFile."hypr/hyprlock.conf".text = ''
    $accent  = rgba(00BEFFff)
    $accent2 = rgba(B4FFDCff)
    $bg      = rgba(0F1219D9)
    $fg      = rgba(EEF2F8F2)
    $fgDim   = rgba(C8D3E6CC)
    $font    = JetBrainsMono Nerd Font

    general {
        hide_cursor = false
        grace = 0
        no_fade_in = false
        disable_loading_bar = true
        ignore_empty_input = true
    }

    background {
        monitor =
        path = screenshot
        blur_passes = 4
        blur_size = 8
        contrast = 0.9
        brightness = 0.55
        vibrancy = 0.2
        vibrancy_darkness = 0.05
    }

    # Klokke
    label {
        monitor =
        text = cmd[update:1000] date +"%H:%M"
        font_size = 140
        font_family = $font
        color = $fg
        shadow_passes = 3
        shadow_size = 6
        shadow_color = rgba(00000099)
        position = 0, 240
        halign = center
        valign = center
    }

    # Dato
    label {
        monitor =
        text = cmd[update:60000] date +"%A, %d %B %Y"
        font_size = 22
        font_family = $font
        color = $fgDim
        position = 0, 130
        halign = center
        valign = center
    }

    # Brukernavn
    label {
        monitor =
        text =   $USER
        font_size = 18
        font_family = $font
        color = $fg
        position = 0, -40
        halign = center
        valign = center
    }

    # Passord
    input-field {
        monitor =
        size = 360, 64
        outline_thickness = 2
        dots_size = 0.22
        dots_spacing = 0.35
        dots_center = true
        outer_color = $accent
        inner_color = $bg
        font_color = $fg
        fade_on_empty = false
        placeholder_text = <i><span foreground="##C8D3E699">Skriv passord...</span></i>
        hide_input = false
        rounding = 18
        check_color = $accent2
        fail_color = rgba(FF4650ff)
        fail_text = <i>$FAIL</i>
        fail_transition = 300
        capslock_color = rgba(FFC846ff)
        position = 0, -120
        halign = center
        valign = center
    }
  '';
}
