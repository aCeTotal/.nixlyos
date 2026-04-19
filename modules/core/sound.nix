{ config, lib, pkgs, ... }:

{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    wireplumber.extraConfig = {
      "10-default-source" = {
        "wireplumber.settings" = {
          "default.audio.source" = "alsa_input.pci-0000_00_1f.3.analog-stereo";
        };
      };

      # WirePlumber 0.5 introduced a hard passthrough check: if the
      # client requests spdif-<codec> and the target route's
      # iec958Codecs list does not contain <codec>, linking is
      # rejected with "no target node available". WP 0.4 did not
      # enforce this, so upgrades inherited a stale codec list from
      # persisted state and silently broke passthrough.
      #
      # Samsung TV on the Arc A770 HDMI output advertises PCM, AC-3
      # and E-AC-3 in its ELD. Pin the card's iec958 codec list to
      # exactly those so WP 0.5 accepts AC3/EAC3 passthrough from
      # mpv/retroarch regardless of whatever the default-routes
      # state file happens to contain.
      "51-hdmi-iec958-codecs" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "device.name" = "alsa_card.pci-0000_04_00.0"; }
            ];
            actions = {
              update-props = {
                "api.alsa.iec958.codecs" = [ "PCM" "AC3" "EAC3" ];
              };
            };
          }
        ];
      };
    };

    extraConfig = {
      pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 48000 44100 96000 192000 ];
          "default.clock.quantum" = 128;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 256;
          "log.level" = 2;
        };
        "stream.properties" = {
          "node.latency" = "128/48000";
          "resample.quality" = 9;
        };
      };
      pipewire-pulse."92-low-latency" = {
        "stream.properties" = {
          "node.latency" = "128/48000";
          "resample.quality" = 9;
        };
      };
    };
  };

  # Migrate stale WP-0.4 persisted route state on first WP-0.5 start.
  # The old state commonly held iec958Codecs=[PCM,DTS,DTS-HD] on the
  # Arc A770 HDMI output even though the TV only supports [PCM,AC3,
  # EAC3]; WP 0.5 then refuses passthrough. This oneshot rewrites the
  # offending entry before wireplumber starts. Idempotent — if the
  # list is already correct the sed is a no-op.
  systemd.user.services.wireplumber-route-migrate = {
    description = "Rewrite stale WirePlumber 0.4 route state for WP 0.5";
    before = [ "wireplumber.service" ];
    partOf = [ "wireplumber.service" ];
    wantedBy = [ "wireplumber.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wp-route-migrate" ''
        set -u
        STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/wireplumber/default-routes"
        [ -f "$STATE" ] || exit 0
        ${pkgs.gnused}/bin/sed -i \
          's|"iec958Codecs":\[\s*"PCM",\s*"DTS",\s*"DTS-HD"\s*\]|"iec958Codecs":["PCM", "AC3", "EAC3"]|g' \
          "$STATE"
      '';
    };
  };

  # Handy tools for controlling PipeWire and routing audio between apps/devices
  environment.systemPackages = with pkgs; [
    # PipeWire + control CLIs
    pipewire           # provides pw-cli, pw-top, pw-dump, pw-link
    wireplumber        # provides wpctl

    # GUI mixers and patchbays
    pavucontrol        # PulseAudio-style mixer (works with pipewire-pulse)
    pwvucontrol        # PipeWire native volume control
    crosspipe          # PipeWire patchbay (replaces helvum)
    qpwgraph           # Qt patchbay for PipeWire/JACK

    # Audio utilities
    alsa-utils         # includes alsamixer and basic ALSA tools
  ];
}
