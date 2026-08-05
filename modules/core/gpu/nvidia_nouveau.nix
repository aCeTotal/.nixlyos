{ config, lib, pkgs, ... }:

# Fermi og eldre (GeForce 400/500-serien og bakover). detect-hw.sh velger
# denne fordi den proprietaere driveren de trenger — legacy_390 / legacy_340 —
# er markert `broken = true` i nixpkgs: den bygger ikke mot moderne
# kernel-serier. Et system som IKKE bygger er verre enn nouveau, saa her
# brukes den in-tree driveren, som fungerer paa alle kernler.
#
# Vil du likevel proeve den proprietaere: pin branch i
# scripts/laptop-register (legacy_390 / legacy_340). Da velges
# gpu/nvidia_legacy.nix i stedet, og du maa i tillegg pinne en eldre
# boot.kernelPackages og tillate broken-pakker.

let
  gpu = import ./detected.nix;
in
{
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      libvdpau-va-gl
    ];
  };

  # nouveau er in-tree; last den i initrd saa KMS er oppe foer stage 2.
  boot.initrd.kernelModules = [ "nouveau" ];

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    mesa-demos
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  warnings = [
    "gpu/nvidia_nouveau.nix: kortet (arkitektur: ${gpu.nvidiaArch}) stoettes bare av NVIDIA legacy_390/legacy_340, som er broken i nixpkgs paa moderne kernel. Bruker nouveau — spillytelse er langt under den proprietaere driveren, og reclocking er begrenset."
  ];
}
