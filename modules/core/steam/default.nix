{ pkgs, ... }:

let
  gameWrap = pkgs.callPackage ./gamewrap.nix {
    launchParams = import ./launchparams.nix;
  };
  autoconfig = pkgs.callPackage ./autoconfig.nix { inherit gameWrap; };
in
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;

    package = pkgs.steam.override {
      # `-cef-disable-gpu-compositing` for the nixlytile/xwayland-satellite
      # black-window fix; the flag is vendor-agnostic (Intel/AMD/Nvidia).
      extraArgs = "-cef-disable-gpu-compositing";
      # Runs on the host before bubblewrap, on every launch: GE-Proton
      # everywhere, Library start page, notification popups off. Never fatal.
      extraPreBwrapCmds = "${autoconfig} || true";
    };

    extraCompatPackages = [ pkgs.proton-ge-bin ];

    extraPackages = with pkgs; [
      gamemode
      libGL
      libglvnd
    ];
  };

  hardware.steam-hardware.enable = true;
}
