{ config, lib, pkgs, ... }:

# Gamle NVIDIA-kort. detect-hw.sh velger denne naar arkitekturen fra
# PCI-device-ID krever en annen driver-branch enn `latest`:
#
#   Maxwell / Pascal / Volta  ->  legacy_580   (droppet i 590+)
#   Kepler                    ->  legacy_470
#   Fermi                     ->  legacy_390
#   Tesla                     ->  legacy_340
#
# Branchen leses fra den genererte gpu/detected.nix og kan pinnes manuelt i
# scripts/laptop-register om heuristikken gjetter feil.

let
  gpu = import ./detected.nix;
  np = config.boot.kernelPackages.nvidiaPackages;

  # Fall tilbake til latest om nixpkgs ikke har branchen (f.eks. etter at en
  # legacy-branch er fjernet oppstroems).
  branch = if builtins.hasAttr gpu.nvidiaBranch np then gpu.nvidiaBranch else "latest";

  # 470 var siste branch med GBM. 390/340 har ingen — wlroots og SDDM
  # Wayland kan ikke kjoere paa dem.
  gbmOk = !(builtins.elem branch [ "legacy_390" "legacy_340" ]);

  hybrid = gpu.intel != "";
in
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
    package = np.${branch};

    modesetting.enable = gbmOk;
    # persistenced/settings-binaerene finnes ikke i de eldste pakkene.
    nvidiaPersistenced = gbmOk;
    nvidiaSettings = false;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    # Alltid proprietaer: open-modulene finnes bare for Turing+.
    open = false;

    # Prime bare naar det faktisk finnes en iGPU (hybrid-laptop). Bus-IDene
    # er detektert, ikke hardkodet.
    prime = lib.mkIf (hybrid && gbmOk) {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = gpu.intel;
      nvidiaBusId = gpu.nvidia;
    };
  };

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" ]
      ++ lib.optional gbmOk "nvidia_drm";

    kernelParams =
      # PAT for GPU-mappinger: raskere CPU->GPU-opplasting (teksturer,
      # buffere). Parameteret finnes i alle branchene her.
      [ "nvidia.NVreg_UsePageAttributeTable=1" ]
      ++ lib.optionals gbmOk [
        "nvidia_drm.modeset=1"
        "nvidia_drm.fbdev=1"
        # ReBAR-parameteret kom i 465 — ukjent parameter paa 390/340 ville
        # gitt modprobe-feil i initrd.
        "nvidia.NVreg_EnableResizableBar=1"
        # Hopper nullstilling av nyallokert systemminne for GPU-en — raskere
        # allokeringer under asset-streaming. Samme trust-modell som
        # mitigations=off i boot.nix.
        "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
      ];
  };

  # NVENC/NVDEC finnes paa Kepler og nyere, men VA-API-broen
  # (nvidia-vaapi-driver) krever 470+ — den er bygget mot NVDEC-APIet som
  # 390/340 ikke har. Uten den maa opptak gaa direkte mot NVENC i ffmpeg/OBS.
  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    nvtopPackages.full
  ] ++ lib.optionals gbmOk [
    egl-wayland
    nvidia-vaapi-driver
  ];

  # Shader-cache og VRR/threaded GL: samme gaming-innstillinger som paa nye
  # kort, alle branchene stoetter dem.
  environment.sessionVariables = {
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # GBM/GLX-vendor bare naar branchen faktisk har GBM (470+), og aldri naar
  # en iGPU driver panelet (samme svartskjerm-felle som i nvidia_intel.nix).
  environment.variables = lib.mkIf (gbmOk && !hybrid) {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
  };

  systemd.services.display-manager.environment = lib.mkIf (gbmOk && !hybrid) {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Reelle blokkere som ikke kan fikses i denne modulen:
  warnings =
    lib.optional (!gbmOk)
      "gpu/nvidia_legacy.nix: ${branch} har ingen GBM-stoette. SDDM Wayland og nixlytile starter ikke paa dette kortet (arkitektur: ${gpu.nvidiaArch})."
    ++ lib.optional (branch != "latest")
      "gpu/nvidia_legacy.nix: ${branch} bygger bare mot eldre kernel-serier. Feiler kernel-modulen, maa boot.kernelPackages pinnes lavere enn zen/cachyos-valget i boot.nix.";
}
