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

  # Handy tools for controlling PipeWire and routing audio between apps/devices
  environment.systemPackages = with pkgs; [
    # PipeWire + control CLIs
    pipewire           # provides pw-cli, pw-top, pw-dump, pw-link
    wireplumber        # provides wpctl

    # GUI mixers and patchbays
    pavucontrol        # PulseAudio-style mixer (works with pipewire-pulse)
    pwvucontrol        # PipeWire native volume control
    helvum             # GTK patchbay for PipeWire nodes
    qpwgraph           # Qt patchbay for PipeWire/JACK

    # Audio utilities
    easyeffects        # per-app/system effects on PipeWire
    alsa-utils         # includes alsamixer and basic ALSA tools
  ];
}
