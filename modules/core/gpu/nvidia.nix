{ config, lib, pkgs, ... }:

let
  nvtopPkg = (pkgs.nvtopPackages.full or (pkgs.nvtopPackages.nvidia or (pkgs.nvtop or null)));
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.latest;
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
    package = nvidiaPackage;
  };

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" "nvidia_drm" ];
    kernelParams = [
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "nvidia.NVreg_EnableGpuFirmware=0"    # Lavere latency på Turing (2080 Ti)
    ];
  };

  # ── GPU-ytelsesmodus ved boot (Wayland-kompatibel, erstatter nvidia-settings) ──
  systemd.services.nvidia-performance = {
    description = "NVIDIA GPU performance tuning";
    after = [ "nvidia-persistenced.service" ];
    wants = [ "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "nvidia-perf" ''
        smi="${nvidiaPackage.bin}/bin/nvidia-smi"

        # Persistence mode (holder GPU klar)
        $smi -pm 1

        # Power limit til maks (2080 Ti: 300W)
        $smi -pl 300

        # Lås GPU-klokker til maks boost-område
        $smi -lgc 1350,1995
      '';
      ExecStop = pkgs.writeShellScript "nvidia-perf-reset" ''
        smi="${nvidiaPackage.bin}/bin/nvidia-smi"
        $smi -rgc        # Reset klokkelås
        $smi -rpl         # Reset power limit
      '';
    };
  };

  environment.systemPackages =
    (with pkgs; [
      vulkan-tools
      libva-utils
      egl-wayland
      nvidia-vaapi-driver
    ])
    ++ lib.optional (nvtopPkg != null) nvtopPkg;

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";  # Behold shader-cache mellom økter
    __GL_THREADED_OPTIMIZATIONS = "1";           # Trådede GL-optimaliseringer
  };
}
