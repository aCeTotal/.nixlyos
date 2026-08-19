{ config, lib, pkgs, ... }:

# NVIDIA-only host: like gpu/nvidia.nix but without prime, which needs an intelBusId.

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
  };

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" "nvidia_drm" ];
    kernelParams = [
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
      # PAT for GPU mappings, faster CPU-to-GPU uploads.
      "nvidia.NVreg_UsePageAttributeTable=1"
      # Skip zeroing new GPU memory; accepted on a single-user desktop.
      "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
      # ReBAR needs an Ampere+ vbios, otherwise a no-op.
      "nvidia.NVreg_EnableResizableBar=1"
    ];
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    egl-wayland
    nvidia-vaapi-driver
    nvtopPackages.full
    nvfancontrol
  ];

  # System-wide so SDDM sees them; without these the greeter renders black.
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
  };

  # No __GL_THREADED_OPTIMIZATIONS here: it hangs GL/EGL clients on NVIDIA-only hosts.
  environment.sessionVariables = {
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";   # 10 GiB
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # Same vars on the unit too, in case the PAM env import races.
  systemd.services.display-manager.environment = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Fan curve for nvfancontrol: silent at idle, hard cap at 85 °C.
  environment.etc."xdg/nvfancontrol.conf".text = ''
    # Temp(°C)  Fan(%)
    20  0
    35  0
    40  25
    45  30
    50  35
    55  40
    60  50
    65  60
    70  70
    75  80
    80  95
    83  100
  '';

  systemd.services.nvfancontrol = {
    description = "NVIDIA GPU Fan Control";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    requires = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.nvfancontrol}/bin/nvfancontrol -l 0,100 -f";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
