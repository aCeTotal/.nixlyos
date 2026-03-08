{ system, inputs, lib, pkgs, ... }:

{
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      # Deaktivert - lanzaboote tar over for systemd-boot
      systemd-boot.enable = lib.mkForce false;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd.systemd.enable = true;
    consoleLogLevel = 3;
    tmp.cleanOnBoot = true;

    plymouth = {
      enable = true;
      theme = "matrix";
      themePackages = [ pkgs.plymouth-matrix-theme ];
    };

    supportedFilesystems = [ "ext4" "btrfs" "vfat" "ntfs3" ];

    kernelPackages = pkgs.linuxPackages_zen;

    kernelPatches = [{
      name = "disable-nova-core";
      patch = null;
      structuredExtraConfig = {
        DRM_NOVA = lib.kernel.no;
      };
    }];

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
    ];
  };

  # sbctl for å administrere Secure Boot-nøkler
  environment.systemPackages = [ pkgs.sbctl ];

  # Aktiver TPM2-støtte
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  # Registrer Secure Boot-nøkler automatisk hvis systemet er i Setup Mode
  # (bevarer Microsoft-nøkler)
  system.activationScripts.secureboot-enroll = lib.stringAfter [ "etc" ] ''
    SBCTL="${pkgs.sbctl}/bin/sbctl"
    if $SBCTL status 2>/dev/null | grep -q "Setup Mode:.*Enabled"; then
      echo "Setup Mode aktiv - registrerer nøkler med Microsoft-nøkler bevart..."
      $SBCTL enroll-keys --microsoft
    fi
  '';

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Gaming
    "vm.max_map_count" = 16777216; # Kreves av mange spill (Star Citizen, etc.)
  };

  services.fstrim.enable = true;
}
