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
      # WirePlumber 0.5 introduced a hard passthrough check: if the client
      # requests spdif-<codec> and the target route's iec958Codecs list does
      # not contain <codec>, linking is rejected with "no target node
      # available". WP 0.4 did not enforce this, so upgrades inherited stale
      # codec lists from persisted state and silently broke passthrough.
      #
      # Pin the iec958 codec list on every Intel HDMI codec to {PCM, AC3,
      # EAC3} — the safe intersection that every HDMI-1.4+ TV understands.
      # Matching by alsa.card_name regex makes this work on any host
      # regardless of which PCI slot the Arc/iGPU lives in.
      "51-hdmi-iec958-codecs" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "alsa.card_name" = "~HDA Intel HDMI"; }
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

  # Migrate stale WP-0.4 persisted route state on first WP-0.5 start. WP
  # otherwise keeps the old iec958Codecs list from the persisted file even
  # though the rule above sets a new card-level list — WP merges the two and
  # the persisted entry wins. Replace any iec958Codecs array in the state
  # with the safe {PCM,AC3,EAC3} list so passthrough requests link cleanly.
  # Idempotent: re-running over an already-rewritten file is a no-op.
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
        ${pkgs.gnused}/bin/sed -i -E \
          's|"iec958Codecs":\[[^]]*\]|"iec958Codecs":["PCM", "AC3", "EAC3"]|g' \
          "$STATE"
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    pipewire           # provides pw-cli, pw-top, pw-dump, pw-link
    wireplumber        # provides wpctl

    pavucontrol
    pwvucontrol
    crosspipe
    qpwgraph

    alsa-utils
  ];
}
