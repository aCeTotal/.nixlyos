{ pkgs, lib, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    extraConfig = {
      pipewire."10-lowlatency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 48000 ];
          "default.clock.quantum" = 128;
          "default.clock.min-quantum" = 64;
          "default.clock.max-quantum" = 128;
          "resample.quality" = 1;
        };
      };

      client."10-lowlatency" = {
        "stream.properties" = {
          "node.latency" = "128/48000";
          "resample.quality" = 1;
          "pulse.min.req" = "128/48000";
          "pulse.default.req" = "128/48000";
          "pulse.max.req" = "128/48000";
        };
      };
    };
  };

  services.pulseaudio.enable = false;
  services.pipewire.wireplumber.enable = true;

  security.rtkit.enable = true;

  # Bluetooth config is in modules/core/gaming.nix
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    blueman
    pipewire
    wireplumber
    pavucontrol
    pwvucontrol
    helvum
  ];

}
