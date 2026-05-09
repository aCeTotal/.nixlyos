{ config, lib, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
      ocl-icd
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      intel-media-driver
      libvdpau-va-gl
    ];
  };

  # Intel Arc A770 (DG2-512 / Alchemist / Xe-HPG). xe is the supported path
  # on kernel ≥6.13 and matches/exceeds i915 with Mesa 25+. Always uses GuC
  # submission, supports HuC firmware → AV1 / VP9 hardware media intact.
  boot.initrd.kernelModules = [ "xe" ];

  # force_probe=* makes xe claim Arc devices regardless of driver-priority
  # tie-break with i915. Belt-and-braces — most 6.13+ kernels do it anyway.
  boot.kernelParams = [
    "xe.force_probe=*"
  ];

  services.xserver.videoDrivers = [ "modesetting" ];

  # GuC/HuC firmware blobs live in linux-firmware. nixos-hardware/common-pc
  # already enables redistributable firmware; explicit here so an Intel-only
  # host stays self-contained.
  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    intel-gpu-tools
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Intel-only host: replace SDDM with ly + autologin into niri.
  # SDDM.nix imports unconditionally in modules/core/default.nix, so force it off.
  services.displayManager.sddm.enable = lib.mkForce false;

  services.displayManager.ly.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "total";
  };
}
