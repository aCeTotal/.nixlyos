{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
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

  environment.sessionVariables = {
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
    # NixlyOS GPU Fan Curve - RTX 2080 Ti
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

  # nvfancontrol systemd service - starts at boot
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
