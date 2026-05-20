{ config, lib, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      intel-media-driver       # iHD VA-API driver (HW decode/encode)
      vpl-gpu-rt               # oneVPL runtime (AV1 / VP9 / HEVC on DG2)
      intel-compute-runtime    # OpenCL / Level Zero
      ocl-icd
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      intel-media-driver
      libvdpau-va-gl
    ];
  };

  # Intel Arc DG2 / Alchemist / Xe-HPG. Pin to i915 — xe is the long-term
  # driver but for DG2 (A310/A380/A580/A750/A770) i915 + iHD is the hardened
  # combo. iHD VA-API on Xe + DG2 has SIGBUS issues in mmap of GPU BOs.
  # force_probe lists every shipping DG2 PCI ID so this works regardless of
  # which Arc variant the host has.
  boot.initrd.kernelModules = [ "i915" ];

  boot.kernelParams = [
    # All current DG2 device IDs (A310 → A770, incl. mobile and 8/16 GB LEs):
    # 5690 5691 5692 5693 5694 5695 5696 5697 56a0 56a1 56a2 56a3 56a5 56a6
    "i915.force_probe=5690,5691,5692,5693,5694,5695,5696,5697,56a0,56a1,56a2,56a3,56a5,56a6"
    "xe.force_probe=!5690,!5691,!5692,!5693,!5694,!5695,!5696,!5697,!56a0,!56a1,!56a2,!56a3,!56a5,!56a6"

    # HDMI audio reliability: disable runtime PM on the HDA codec so the
    # HDMI audio sink does not vanish from ALSA after idle. Without this the
    # PipeWire HDMI sink intermittently disappears on Arc + TV combos.
    "snd_hda_intel.power_save=0"

    # Keep KMS state intact across boot stages — preserves the EDID-derived
    # mode through initrd → userspace handoff, avoiding a renegotiation that
    # some TVs answer slowly (and which would otherwise drop to a fallback
    # mode before the compositor starts).
    "i915.fastboot=1"
  ];

  services.xserver.videoDrivers = [ "modesetting" ];

  # GuC/HuC firmware blobs live in linux-firmware. nixos-hardware/common-pc
  # already enables redistributable firmware; explicit here so an Intel-only
  # host stays self-contained.
  hardware.enableRedistributableFirmware = true;

  # HDMI audio power-save off at the ALSA module level too (matches the
  # kernel-param above; modprobe.d wins on module reload). Keeps the codec
  # awake so EDID/ELD stays populated for PipeWire to find the HDMI sink.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';

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
}
