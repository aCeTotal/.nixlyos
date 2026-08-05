{ lib, config, pkgs, ... }:

let
  kp = config.boot.kernelPackages;
  msiEcPkg = if kp ? msi-ec then kp.msi-ec else if kp ? msi_ec then kp.msi_ec else null;
  mccPkg = if pkgs ? mcontrolcenter then pkgs.mcontrolcenter else null;

  # Alle EC-firmwareversjoner msi-ec har en konfig for, hentet ut av
  # driverkilden ved bygg. Formatet er <board><EMS-nr>.<revisjon>, f.eks.
  # 16V3EMS1.106.
  fwList = pkgs.runCommand "msi-ec-firmware-list" { } ''
    grep -ohE '"[0-9A-Z]+E[A-Z0-9]+\.[0-9]+"' ${msiEcPkg.src}/msi-ec.c \
      | tr -d '"' | sort -u > $out
  '';

  # msi-ec nekter aa laste hvis EC-firmwaren ikke staar i lista over kjente
  # versjoner (load_configuration -> -EOPNOTSUPP). Mange MSI-laptoper kjoerer
  # en revisjon som ikke er registrert enda, selv om hovedkortet er stoettet.
  # Derfor: proev ren autodeteksjon foerst, og bare hvis den feiler, les
  # EC-firmwaren selv (samme offset som driveren: 0xa0 = 160, 12 byte, via
  # ec_sys) og pin til konfigen for samme hovedkort + EMS-nummer. Ingen
  # treff paa hovedkortet = hardware msi-ec ikke stoetter; da lastes ingenting.
  autoload = pkgs.writeShellScript "msi-ec-autoload" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.kmod pkgs.coreutils pkgs.gnugrep ]}

    if modprobe msi-ec 2>/dev/null && [ -d /sys/devices/platform/msi-ec ]; then
      echo "msi-ec: EC-firmware stoettet direkte"
      exit 0
    fi

    modprobe ec_sys write_support=1 2>/dev/null || true
    io=/sys/kernel/debug/ec/ec0/io
    if [ ! -r "$io" ]; then
      echo "msi-ec: fant ikke $io — kan ikke lese EC-firmware"
      exit 0
    fi

    ver=$(dd if="$io" bs=1 skip=160 count=12 status=none | tr -cd '[:alnum:].')
    case "$ver" in
      *.*) ;;
      *) echo "msi-ec: ulesbar EC-firmware ('$ver')"; exit 0 ;;
    esac

    cand=$(grep -m1 "^''${ver%.*}\." ${fwList} || true)
    if [ -z "$cand" ]; then
      echo "msi-ec: EC-firmware $ver ikke stoettet (ingen konfig for ''${ver%.*})"
      exit 0
    fi

    echo "msi-ec: EC-firmware $ver ukjent for driveren — bruker konfig $cand"
    modprobe msi-ec firmware="$cand" || echo "msi-ec: lasting feilet"
    exit 0
  '';
in
{
  # Build the msi-ec kernel module for the running kernel, if available
  boot.extraModulePackages = lib.mkAfter (lib.optional (msiEcPkg != null) msiEcPkg);

  # ec_sys lastes her; msi-ec lastes av msi-ec-autoload (som kan trenge en
  # firmware=-parameter). Ligger den i kernelModules i stedet, feiler
  # systemd-modules-load.service paa hver boot naar firmwaren er ukjent.
  boot.kernelModules = lib.mkAfter [ "ec_sys" ];

  # Allow EC writes if you intend to change fan curves, etc.
  boot.extraModprobeConfig = lib.mkAfter ''
    options ec_sys write_support=1
  '';

  # Install mcontrolcenter if available (stable or unstable)
  environment.systemPackages = lib.mkAfter (lib.optional (mccPkg != null) mccPkg);

  # Make msi-ec sysfs nodes writable for userspace fan/shift control
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="platform", KERNEL=="msi-ec", RUN+="/bin/sh -c 'chmod 0666 /sys/devices/platform/msi-ec/fan_mode /sys/devices/platform/msi-ec/shift_mode /sys/devices/platform/msi-ec/cooler_boost 2>/dev/null || true'"
  '';

  systemd.services.msi-ec-autoload = lib.mkIf (msiEcPkg != null) {
    description = "Load msi-ec with a matching EC firmware configuration";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = autoload;
    };
  };

  # shift_mode/fan_mode settes ikke herfra — modulen gjoer msi-ec tilgjengelig,
  # valg av profil er opp til brukerspace (mcontrolcenter / sysfs).
}
