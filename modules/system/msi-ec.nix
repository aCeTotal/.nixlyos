{ lib, config, pkgs, pkgs-unstable ? null, ... }:

let
  kp = config.boot.kernelPackages;
  # Try both common attribute spellings to avoid eval failure if one is missing
  msiEcPkg = if kp ? msi-ec then kp.msi-ec else if kp ? msi_ec then kp.msi_ec else null;
  # Prefer stable if available; fall back to unstable if needed
  unstablePkgs = pkgs-unstable;
  mccPkg =
    if pkgs ? mcontrolcenter then pkgs.mcontrolcenter
    else if unstablePkgs ? mcontrolcenter then unstablePkgs.mcontrolcenter
    else null;
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
  boot.extraModprobeConfig = lib.mkAfter ''
    options ec_sys write_support=1
  '';

  # Install mcontrolcenter if available (stable or unstable)
  environment.systemPackages = lib.mkAfter (lib.optional (mccPkg != null) mccPkg);
}
