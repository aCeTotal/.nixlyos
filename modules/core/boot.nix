{ system, inputs, lib, pkgs, ... }:

{
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # Ensure this mounts your ESP
      };

      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;  # Behold maks 5 generasjoner i boot
    };

    initrd.systemd.enable = true;
    consoleLogLevel = 3;
    tmp.cleanOnBoot = true;

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
      "loglevel=3"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
    ];
  };

    #  security = {
    #apparmor.enable = true;
    #sudo.wheelNeedsPassword = true;
    #tpm2.enable = true;
    #tpm2.pkcs11.enable = true;
    #tpm2.tctiEnvironment.enable = true;
    #};

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
  };

  services.fstrim.enable = true;
}
