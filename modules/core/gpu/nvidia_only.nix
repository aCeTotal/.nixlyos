{ config, lib, pkgs, ... }:

# Ren NVIDIA-host: dGPU driver alle utganger direkte, ingen iGPU i systemet.
# Identisk med gpu/nvidia.nix bortsett fra at prime-blokka er borte — prime
# krever en intelBusId, og reverseSync mot en iGPU som ikke finnes gir svart
# skjerm. detect-hw.sh velger denne naar ingen Intel iGPU er detektert.

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
      # PAT for GPU-mappinger — raskere CPU->GPU-opplasting (streaming av
      # teksturer/buffere i spill).
      "nvidia.NVreg_UsePageAttributeTable=1"
      # Hopper nullstilling av nyallokert systemminne for GPU-en — raskere
      # allokeringer under asset-streaming. Tradeoff: stale RAM-innhold
      # synlig for driveren (samme trust-modell som mitigations=off i
      # boot.nix).
      "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
      # ReBAR: krever Ampere+ vbios, ellers no-op.
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

  # System-wide vars (read by SDDM and other system services, not just user
  # sessions). SDDM Wayland on NVIDIA proprietary needs GBM_BACKEND and
  # __GLX_VENDOR_LIBRARY_NAME set in the display-manager environment, else
  # the greeter cannot pick the NVIDIA GBM/EGL impl and renders black.
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
  };

  # Gaming: VRR/G-Sync tillatt, og en shader-cache som aldri trimmes midt i
  # en sesjon (cache-eviction viser seg som recompile-hitch).
  # __GL_THREADED_OPTIMIZATIONS er bevisst ikke satt: den henger/krasjer
  # GL/EGL-klienter (alacritty, appd) paa ren NVIDIA.
  environment.sessionVariables = {
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";   # 10 GiB
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # Belt-and-braces: set the same vars on the display-manager unit so SDDM's
  # systemd environment carries them even if PAM env import races.
  systemd.services.display-manager.environment = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # GPU fan curve config for nvfancontrol
  # Format: temperature(°C)  fan_speed(%)
  # Designed for silence at idle, aggressive ramp before 85°C
  environment.etc."xdg/nvfancontrol.conf".text = ''
    # NixlyOS GPU Fan Curve
    # Goal: Maximum silence, hard cap at 85°C
    #
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
