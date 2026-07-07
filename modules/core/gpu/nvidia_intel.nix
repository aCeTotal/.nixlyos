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

    # Dynamic Boost DISABLED. The theory was nvidia-powerd arbitrates the shared
    # TGP up to 80 W under load. In practice on this unit (GS66 Stealth 10UG, EC
    # fw 16V3EMS1.102) powerd gets no valid platform telemetry from the SBIOS and
    # pins the "GPU Ceiling Power Limit" at its 10 W FLOOR instead of raising it —
    # measured: Current Power Limit 10 W vs Default 80 W, GPU stuck P8 / 210 MHz /
    # ~27 W at 99 % util, throttle reason "SW Power Cap" permanently Active.
    # Disabling powerd drops the dynamic ceiling so the driver uses the static
    # 80 W default limit instead. (shift_mode=turbo via msi-ec does NOT lift the
    # cap on this firmware — verified by cycling every shift/fan/cooler value.)
    dynamicBoost.enable = false;

    # GSP firmware DISABLED experiment. On this unit the GPU "Ceiling Power
    # Limit" is pinned to its 10 W FLOOR on AC even with nvidia-powerd off
    # (measured: Current 10 W / Default 80 W, P8, "SW Power Cap" Active at 99 %
    # util). Root cause is the SBIOS reacting to an underpowered USB-C PD
    # charger (~100 W) instead of the original 230 W barrel adapter — the EC
    # clamps GPU TGP to protect the power budget. GSP firmware enforces that
    # platform ceiling; disabling it moves Dynamic Boost arbitration back into
    # the driver, which may ignore the SBIOS clamp. NOTE: cannot beat the
    # charger — 100 W in can't sustain 80 W GPU + CPU. Real fix = 230 W adapter.
    gsp.enable = false;

    # reverseSync: the NVIDIA dGPU renders the WHOLE session (compositor +
    # apps + games) and reverse-PRIMEs the final framebuffer to the Intel-
    # connected eDP panel.  Removes the per-game cross-GPU buffer copy of the
    # old offload path (game→Nvidia→copy→Intel composite→scanout), so the weak
    # Intel UHD630 is no longer in the game render path.  The compositor is
    # told to use Nvidia as primary renderer via NIXLY_NVIDIA_PRIMARY=1 below
    # (it builds WLR_DRM_DEVICES=<nvidia>:<intel>).
    # Tradeoff: dGPU stays powered for the whole session (more heat/battery);
    # on battery the SBIOS pins it to ~10W regardless (Dynamic Boost DC
    # controller is disabled in firmware — not fixable in software).
    # Offload mode: Intel drives the panel (eDP-1 is Intel-only on this muxless
    # unit — the Nvidia connectors are all disconnected), Nvidia is used only
    # for per-app/game render offload.  reverseSync was black-screening: with
    # Nvidia forced primary the Intel panel became an mgpu *secondary* output
    # and its swapchain alloc failed → output disabled → black.
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
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
    nvtopPackages.full
    egl-wayland
    nvidia-vaapi-driver
  ];

  # NOTE: GBM_BACKEND=nvidia-drm / __GLX_VENDOR_LIBRARY_NAME=nvidia are NOT set
  # system-wide.  In offload mode the compositor + greeter render on Intel; a
  # global nvidia GBM backend forces the Intel primary output onto the Nvidia
  # allocator and black-screens.  Games get the Nvidia env per-process via the
  # nvidia offload path / set_dgpu_env().

  environment.sessionVariables = {
    # NIXLY_NVIDIA_PRIMARY removed — offload mode keeps Intel as the wlroots
    # primary (WLR_DRM_DEVICES=<intel>:<nvidia>, built by gpu.c filter_igpu_*).
    # LIBVA_DRIVER_NAME removed — compositor uses Intel iHD for VA-API decode;
    # games get LIBVA_DRIVER_NAME=nvidia per-process from set_dgpu_env()
    # WLR_NO_HARDWARE_CURSORS removed — compositor handles HW cursor via
    # CpuCursorBuffer (dumb DRM buffer + DMA-BUF, bypasses broken Nvidia GBM)
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";   # 10 GiB shader cache
    MESA_SHADER_CACHE_MAX_SIZE = "10G";
    WLR_RENDERER = "gles2";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
