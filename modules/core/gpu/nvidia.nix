{ config, lib, pkgs, ... }:

let
  nvtopPkg = (pkgs.nvtopPackages.full or (pkgs.nvtopPackages.nvidia or (pkgs.nvtop or null)));
in {
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
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" "nvidia_drm" ];
    kernelParams = [ "nvidia_drm.modeset=1" "nvidia_drm.fbdev=1" ];
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
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
