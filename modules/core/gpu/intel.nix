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

  # Intel Arc A770 (DG2-512 / Alchemist / Xe-HPG). Force i915, block xe.
  # Why: xe is mature for Lunar Lake / Battlemage but DG2 path still ships
  # Mesa "experimental" warning in 2026-05. iHD VA-API on Xe + DG2 SIGBUSes
  # in mmap of GPU BOs (libigdgmm/iHD coredump). i915 + iHD on DG2 is the
  # hardened combo since 2022 — HW decode via iHD works there.
  boot.initrd.kernelModules = [ "i915" ];

  boot.kernelParams = [
    "i915.force_probe=56a0"
    "xe.force_probe=!56a0"
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
