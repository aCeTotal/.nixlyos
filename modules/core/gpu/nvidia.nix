{ config, system, inputs, lib, pkgs, pkgs-unstable, ... }:

let
  nvtopPkg = (pkgs.nvtopPackages.full or (pkgs.nvtopPackages.nvidia or (pkgs.nvtop or null)));

  # ============================================
  # GPU CONFIGURATION OPTIONS
  # Set these based on your hardware:
  # ============================================

  # Set to true for hybrid laptop (Intel + NVIDIA), false for desktop with only NVIDIA
  isHybridLaptop = true;

  # Only needed if isHybridLaptop = true
  # Find your bus IDs with: lspci | grep -E "VGA|3D"
  # Format: "PCI:bus:device:function" (convert hex to decimal)
  intelBusId = "PCI:0:2:0";
  nvidiaBusId = "PCI:1:0:0";

in {
  # Ensure X picks the NVIDIA driver explicitly (Xwayland uses this too)
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
    nvidiaPersistenced = !isHybridLaptop;  # Enable on desktop, disable on laptop
    powerManagement.enable = isHybridLaptop;
    powerManagement.finegrained = isHybridLaptop;  # Only for hybrid laptops
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Prime configuration - only for hybrid laptops
    prime = lib.mkIf isHybridLaptop {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Provides "nvidia-offload" command
      };
      intelBusId = intelBusId;
      nvidiaBusId = nvidiaBusId;
    };
  };

  boot = {
    kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" "nvidia_drm" ];
    kernelParams = [ "nvidia_drm.modeset=1" ];
  };

  environment.systemPackages =
    (with pkgs; [
      vulkan-tools
      libva-utils
      egl-wayland
    ])
    ++ lib.optional (nvtopPkg != null) nvtopPkg;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  } // lib.optionalAttrs (!isHybridLaptop) {
    # Desktop-only: Set NVIDIA as default for everything
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
