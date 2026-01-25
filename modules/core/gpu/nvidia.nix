{ config, system, inputs, lib, pkgs, pkgs-unstable, ... }:

let
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
    powerManagement.enable = true;
    powerManagement.finegrained = true;  # Kreves for offload
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Prime offload for hybrid Intel + NVIDIA laptop
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Gir "nvidia-offload" kommando
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
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
    # For offload-modus: IKKE sett __GLX_VENDOR_LIBRARY_NAME globalt
    # Det vil tvinge alt til NVIDIA. La Prime håndtere dette.
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Rely on hardware.nvidia.nvidiaPersistenced above; no extra unit needed.

  # No additional performance-tweaking services; keep config simple.
}
