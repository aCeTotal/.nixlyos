{ system, inputs, lib, pkgs, ... }:

{
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 2;
      timeout = 0;
    };

    # lanzaboote = {
    #   enable = true;
    #   pkiBundle = "/var/lib/sbctl";
    #   configurationLimit = 1;
    # };

    initrd.systemd.enable = true;
    consoleLogLevel = 3;
    tmp.cleanOnBoot = true;

    plymouth.enable = false;

    supportedFilesystems = [ "ext4" "btrfs" "vfat" "ntfs3" ];

    kernelPackages = pkgs.linuxPackages_zen;

    kernelPatches = [{
      name = "kernel-config-fixes";
      patch = null;
      structuredExtraConfig = {
        DRM_NOVA = lib.kernel.no;
        PREEMPT_LAZY = lib.mkForce (lib.kernel.no);
      };
    }];

    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      # Skip serial port probing (saves ~5.6s on hardware without serial ports)
      "8250.nr_uarts=0"
      # CachyOS-style perf params
      "transparent_hugepage=madvise"  # THP only on madvise — best for desktops/games
      "random.trust_cpu=on"            # use RDRAND for early entropy (faster boot)
      "nowatchdog"                     # disable hardware watchdog (CPU savings)
      "nmi_watchdog=0"                 # disable NMI watchdog (CPU savings)
    ];

    blacklistedKernelModules = [ "8250_pci" ];
  };

  # sbctl for å administrere Secure Boot-nøkler
  environment.systemPackages = [ pkgs.sbctl ];

  # Aktiver TPM2-støtte
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  # Skip while lanzaboote disabled — sbctl status fork+grep on every
  # activation costs ~hundreds of ms for nothing. Re-enable when needed.

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Nettverkshardening
    "net.ipv4.conf.all.rp_filter" = 1;              # reverse path filtering
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;        # avvis ICMP redirects
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;           # ikke send ICMP redirects
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;      # blokkerer source routing
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;       # smurf attack protection
    "net.ipv4.conf.all.log_martians" = 1;              # logger ugyldige pakker
    "net.ipv4.conf.default.log_martians" = 1;

    # Kernel anti-exploit hardening
    "kernel.yama.ptrace_scope" = 1;                    # begrenser ptrace
    "fs.suid_dumpable" = 0;                            # ingen core dumps fra SUID

    # Gaming
    "vm.max_map_count" = 16777216; # Kreves av mange spill (Star Citizen, etc.)
  };

  services.fstrim.enable = true;
}
