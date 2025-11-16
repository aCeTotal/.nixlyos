{ config, lib, pkgs, ... }:

let
  # nvtop attribute changed across nixpkgs versions; prefer new names.
  nvtopPkg = (pkgs.nvtopPackages.full or (pkgs.nvtopPackages.nvidia or (pkgs.nvtop or null)));
in {
  # Ensure X picks the NVIDIA driver explicitly (Xwayland uses this too)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    # Disable persistenced to avoid service failures and keep defaults simple
    nvidiaPersistenced = false;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
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
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Rely on hardware.nvidia.nvidiaPersistenced above; no extra unit needed.

  # No additional performance-tweaking services; keep config simple.
}
