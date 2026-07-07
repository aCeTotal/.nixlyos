{ lib, config, pkgs, ... }:

let
  kp = config.boot.kernelPackages;
  msiEcPkg = if kp ? msi-ec then kp.msi-ec else if kp ? msi_ec then kp.msi_ec else null;
  mccPkg = if pkgs ? mcontrolcenter then pkgs.mcontrolcenter else null;
in
{
  # Build the msi-ec kernel module for the running kernel, if available
  boot.extraModulePackages = lib.mkAfter (lib.optional (msiEcPkg != null) msiEcPkg);

  # Load modules at boot. modprobe treats '-' and '_' interchangeably.
  boot.kernelModules = lib.mkAfter (
    [ "ec_sys" ]
    ++ (lib.optionals (msiEcPkg != null) [ "msi-ec" ])
  );

  # Allow EC writes if you intend to change fan curves, etc.
  # Force firmware=16V3EMS1.106 for GS66 Stealth 10UG (MS-16V3) with E16V3IMS.105
  boot.extraModprobeConfig = lib.mkAfter ''
    options ec_sys write_support=1
    options msi-ec firmware=16V3EMS1.106
  '';

  # Install mcontrolcenter if available (stable or unstable)
  environment.systemPackages = lib.mkAfter (lib.optional (mccPkg != null) mccPkg);

  # Make msi-ec sysfs nodes writable for userspace fan/shift control
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="platform", KERNEL=="msi-ec", RUN+="/bin/sh -c 'chmod 0666 /sys/devices/platform/msi-ec/fan_mode /sys/devices/platform/msi-ec/shift_mode /sys/devices/platform/msi-ec/cooler_boost 2>/dev/null || true'"
  '';

  # EC defaults to shift_mode=unspecified (low-power), which pins the dGPU at
  # its ~10W TGP floor. Force shift_mode=turbo so the EC grants full dGPU TGP.
  # Without this the GPU boosts a few seconds then clamps. Set on boot and on
  # resume (S3 resets the EC). cooler_boost left off — turbo's own fan curve
  # sustains; flip it on only if you see thermal throttling under load.
  systemd.services.msi-ec-turbo = {
    description = "Set MSI EC shift_mode=turbo for full dGPU TGP";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 50); do [ -w /sys/devices/platform/msi-ec/shift_mode ] && break; sleep 0.1; done; echo turbo > /sys/devices/platform/msi-ec/shift_mode'";
    };
  };

  powerManagement.resumeCommands = lib.mkAfter ''
    echo turbo > /sys/devices/platform/msi-ec/shift_mode 2>/dev/null || true
  '';
}
