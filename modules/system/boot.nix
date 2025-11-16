{ pkgs, nixpkgs-unstable ? null, ... }:

{

    security = {
        apparmor.enable = true;
        audit.enable = true;
        auditd.enable = true;
        sudo.wheelNeedsPassword = true;
        tpm2.enable = true;
        tpm2.pkcs11.enable = true;
        tpm2.tctiEnvironment.enable = true;
    };

    # Boot Loader
    boot = {
        loader = {
            efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot";
            };

            # Bytt fra GRUB til systemd-boot
            systemd-boot = {
                enable = true;
                configurationLimit = 3;
                editor = false;
            };

            timeout = 1;
        };

        kernelParams = [
            "nvme_core.default_ps_max_latency_us=0"
            "intel_pstate=active"
            "i915.enable_fbc=1"      # Framebuffer compression
            "i915.enable_psr=1"      # Panel self refresh
            "i915.fastboot=1"        # Raskere oppstart
        ];

        # Kernel Options
        kernel.sysctl = {
            "kernel.sysrq" = 1;                             # SysRQ

            "net.core.rmem_default" = 4194304;              # 4 MiB
            "net.core.wmem_default" = 4194304;              # 4 MiB
            "net.core.rmem_max"     = 134217728;            # 128 MiB
            "net.core.wmem_max"     = 134217728;            # 128 MiB

            "net.ipv4.tcp_rmem"     = "4096 262144 134217728";
            "net.ipv4.tcp_wmem"     = "4096 262144 134217728";

            "net.ipv4.tcp_keepalive_intvl" = 30;
            "net.ipv4.tcp_keepalive_probes" = 5;
            "net.ipv4.tcp_keepalive_time" = 300;

            "net.ipv4.tcp_fastopen" = 3;                    # klient+server
            "net.ipv4.tcp_mtu_probing" = 1;                 # håndterer PMTU-hull

            "vm.dirty_background_bytes" = 268435456;        # 256 MB
            "vm.dirty_bytes"            = 1073741824;       # 1 GB
            "vm.min_free_kbytes"        = 65536;
            "vm.swappiness"             = 1;
            "vm.vfs_cache_pressure"     = 50;

            "fs.aio-max-nr"  = 1048576;
            "kernel.pid_max" = 4194304;

            "net.ipv4.tcp_congestion_control" = "bbr";
            "net.core.default_qdisc" = "fq";

            "vm.max_map_count" = 16777216;
            "fs.file-max"      = 524288;
        };
        # BOOT settings
        supportedFilesystems = [ "ext4" "ntfs3" "vfat" ];
        # NVIDIA modules are managed in core/gpu/nvidia.nix
        kernelModules = [ "tcp_bbr" ];
        initrd.systemd.enable = true;
        # Use Zen kernel from unstable only if provided
        kernelPackages =
          if nixpkgs-unstable != null then
            (nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}).linuxPackages_zen
          else pkgs.linuxPackages;
        tmp.cleanOnBoot = true;
        modprobeConfig.enable = true;
        extraModprobeConfig = ''
        '';
    };

}
