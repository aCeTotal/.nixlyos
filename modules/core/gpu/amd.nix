{ config, lib, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # ppfeaturemask=0xffffffff aapner amdgpus overdrive-tabeller: fan-kurve,
  # power-limit og clock/voltage-kontroll blir skrivbare fra userspace
  # (CoreCtrl/LACT). Endrer ingenting av seg selv — uten den er knappene
  # bare graaet ut. Gjelder GCN3 og nyere; gamle kort gaar til
  # gpu/amd_legacy.nix.
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    amdgpu_top
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    # RADV, aldri amdvlk: raskere i praktisk taatt alle spill og det Proton
    # forventer. Eksplisitt saa en amdvlk-pakke i profilen ikke kaprer ICDen.
    AMD_VULKAN_ICD = "RADV";
    # glthread flytter GL-kall til en egen traad. Mesa slaar det paa via en
    # per-app-liste; globalt paa gir gevinsten ogsaa i spill som ikke staar
    # der (eldre OpenGL-titler er CPU-bundet i draw-call-loopen).
    mesa_glthread = "true";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
