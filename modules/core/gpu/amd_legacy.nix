{ config, lib, pkgs, ... }:

# Gamle AMD-kort: pre-GCN (TeraScale / R600 og eldre), GCN1 (Southern
# Islands) og GCN2 (Sea Islands). detect-hw.sh velger denne ut fra
# PCI-device-ID.
#
# Kjernepoenget er kernel-parameterne: SI/CIK er bygget inn i BEGGE driverne,
# og kernelen gir dem til `radeon` som standard. radeon har ingen Vulkan og
# ingen moderne VA-API, saa de tvinges over paa amdgpu. Parameterne er
# ufarlige paa pre-GCN-kort — de matcher bare SI/CIK-IDer, saa et
# TeraScale-kort blir vaerende paa radeon der det hoerer hjemme.

{
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  boot.kernelParams = [
    "radeon.si_support=0"
    "amdgpu.si_support=1"
    "radeon.cik_support=0"
    "amdgpu.cik_support=1"
  ];

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
  ];

  # LIBVA_DRIVER_NAME settes bevisst IKKE: radeonsi gjelder GCN, mens et
  # pre-GCN-kort trenger r600-gallium. libva finner riktig driver selv naar
  # variabelen er tom — en hardkodet radeonsi ville brutt VA-API paa
  # TeraScale.
  environment.sessionVariables = {
    # glthread: GL-kall paa egen traad. Gir mest paa nettopp gamle kort, der
    # draw-call-loopen er flaskehalsen.
    mesa_glthread = "true";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  warnings = [
    "gpu/amd_legacy.nix: gammelt AMD-kort (PCI-ID i pre-GCN/GCN1/GCN2-omraadet). RADV/Vulkan krever GCN1 eller nyere — er kortet TeraScale eller eldre, kjoerer det OpenGL-only, og spill via Proton fungerer ikke."
  ];
}
