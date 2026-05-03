{ config, pkgs, lib, inputs, ... }:

let
  opts = import ../core/options.nix;
  isHtpc = opts.systemMode == 2;
in
{

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    autoNumlock = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];
  };

  environment.systemPackages = [ pkgs.sddm-astronaut ];

  # Auto-login when HTPC mode is active (options.nix systemMode = 2)
  services.displayManager.autoLogin = lib.mkIf isHtpc {
    enable = true;
    user = "total";
  };

}
