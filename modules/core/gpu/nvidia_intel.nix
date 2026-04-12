{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      libGL
      libglvnd
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      libGL
      libglvnd
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaPersistenced = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # PRIME offload: Intel renders compositor, games offloaded to NVIDIA
    # via set_dgpu_env() in the compositor (gaming.c).
    # sync.enable would conflict — compositor sets __NV_PRIME_RENDER_OFFLOAD
    # which requires the offload infrastructure, not sync mode.
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" "nvidia_drm" ];
    kernelParams = [
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
    ];
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    egl-wayland
    nvidia-vaapi-driver
    nvtopPackages.full
  ];

  environment.sessionVariables = {
    # LIBVA_DRIVER_NAME removed — compositor uses Intel iHD for VA-API decode;
    # games get LIBVA_DRIVER_NAME=nvidia per-process from set_dgpu_env()
    # WLR_NO_HARDWARE_CURSORS removed — compositor handles HW cursor via
    # CpuCursorBuffer (dumb DRM buffer + DMA-BUF, bypasses broken Nvidia GBM)
    __GL_VRR_ALLOWED = "1";
    WLR_RENDERER = "vulkan";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
