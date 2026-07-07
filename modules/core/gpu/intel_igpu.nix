{ config, lib, pkgs, ... }:

# Intel iGPU (HD/UHD Graphics, Gen8–Gen11). Targets hosts like i7-7700K
# (Kaby Lake, HD Graphics 630, Gen9.5) where hardware video decode must hit
# the iGPU. iHD is the primary VA-API driver; i965 is kept as fallback for
# legacy codecs (VC-1, some MPEG-2 profiles) that the new media stack drops.
#
# Keep this module orthogonal to gpu/intel.nix (Arc DG2). On a hybrid box
# (KBL iGPU + Arc dGPU) both modules import — the package lists merge.

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver       # iHD: Gen8+ VA-API (primary on KBL)
      intel-vaapi-driver       # i965: legacy codec fallback
      libvdpau-va-gl           # VDPAU → VA-API shim for older players
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  boot.initrd.kernelModules = [ "i915" ];

  # Keep KMS state intact across boot stages — preserves the EDID-derived
  # mode through initrd → userspace handoff (no renegotiation flicker).
  boot.kernelParams = [ "i915.fastboot=1" ];

  # GuC/HuC firmware loading on KBL improves media engine power/perf.
  # enable_guc=3 = load both GuC and HuC. Safe on Gen9.5+.
  # enable_fbc=0: FBC på eDP plane 1A ga EAGAIN-commit-storm + "Atomic
  # update failure on pipe A" under fullscreen-video (2026-07-07).
  boot.extraModprobeConfig = ''
    options i915 enable_guc=3 enable_fbc=0
  '';

  hardware.enableRedistributableFirmware = true;
}
