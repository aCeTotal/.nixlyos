{ config, lib, pkgs, ... }:

{
  boot = {
    loader = {
      # Switch to GRUB for broader compatibility with existing installs
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # Ensure this mounts your ESP
      };

      systemd-boot.enable = false;

      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";         # Use EFI, do not touch MBR
        useOSProber = false;       # Do not probe other OS installations
        configurationLimit = 5;
      };

      timeout = 3;
    };

    initrd.systemd.enable = true;

    consoleLogLevel = 3;

    tmp.cleanOnBoot = true;

    supportedFilesystems = [ "ext4" "btrfs" "vfat" "ntfs3" ];

    kernelPackages = pkgs.linuxPackages_zen;

    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
    ];
  };

  security = {
    apparmor.enable = true;
    sudo.wheelNeedsPassword = true;
    tpm2.enable = true;
    tpm2.pkcs11.enable = true;
    tpm2.tctiEnvironment.enable = true;
  };

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
