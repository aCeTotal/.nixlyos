{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    # CEF GPU compositing crashes through rootless XWayland (xwayland-satellite
    # on Niri); UI renders black. Disabling only the compositing layer keeps
    # CEF GPU rendering and is vendor-agnostic (Intel/AMD/Nvidia).
    package = pkgs.steam.override {
      extraArgs = "-cef-disable-gpu-compositing";
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      proton-cachyos
    ];
    extraPackages = with pkgs; [
      gamemode
      libGL
      libglvnd
    ];
  };

  hardware.steam-hardware.enable = true;
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 0;               # Real-time I/O priority
        inotify = 8192;
        inhibit_screensaver = 1;
        softrealtime = "auto";
        reaper_freq = 5;          # Check for game exit every 5s
        desiredgov = "performance"; # CPU governor during gaming
        defaultgov = "powersave";   # Return to powersave after
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        nv_powermizer_mode = 1;   # Prefer max performance for Nvidia
        nv_core_clock_mhz_offset = 0;
        nv_mem_clock_mhz_offset = 0;
      };
      cpu = {
        park_cores = "no";
        pin_cores = "yes";        # Pin game to specific cores
      };
      custom = {
        start = "${pkgs.writeShellScript "gamemode-start" ''
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance || true
          ${pkgs.libnotify}/bin/notify-send 'GameMode' 'Aktivert - Ytelsesmodus på'
        ''}";
        end = "${pkgs.writeShellScript "gamemode-end" ''
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced || true
          ${pkgs.libnotify}/bin/notify-send 'GameMode' 'Deaktivert - Tilbake til normal'
        ''}";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    steamcmd
    gamescope
    mangohud
    goverlay
    vkbasalt
    lutris
    protonup-ng
    protontricks
    wineWow64Packages.staging
    winetricks
    dxvk
    vkd3d
    linuxConsoleTools # for jstest and input debugging
    evtest

    # Vulkan packages
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    pkgsi686Linux.vulkan-loader # 32-bit Vulkan for Steam games

    # Performance monitoring
    libnotify           # For gamemode notifications
    schedtool           # CPU scheduling tool

    # Media playback
    mpv
    yt-dlp
  ];

  # ========================================
  # CONTROLLER HARDWARE SUPPORT
  # ========================================

  # Xbox controller support
  hardware.xpadneo.enable = true;   # Xbox Bluetooth (better than manual xpadneo)
  hardware.xone.enable = true;      # Xbox USB-dongle og kablede kontrollere

  # ========================================
  # BLUETOOTH CONFIGURATION FOR CONTROLLERS
  # ========================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        KernelExperimental = true;
        ControllerMode = "dual";
        FastConnectable = true;

        # Controller pairing
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 15;
        ReconnectIntervals = "1,2,4,8,16,32,64,128";
        ReconnectUUIDs = "00001124-0000-1000-8000-00805f9b34fb,00001200-0000-1000-8000-00805f9b34fb";
      };
      LE = {
        MinAdvertisementInterval = 32;
        MaxAdvertisementInterval = 50;
        ScanIntervalAutoConnect = 30;
        ScanWindowAutoConnect = 30;
      };
      GATT = {
        Cache = "yes";
        Channels = 3;
        KeySize = 7;
      };
    };
  };

  # ========================================
  # UDEV RULES FOR AUTO-DETECTION
  # ========================================
  services.udev.extraRules = ''
    # Xbox Controllers
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="028e", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="028f", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="0291", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02d1", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02dd", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02e3", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02ea", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="0b00", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="0b12", MODE="0666"

    # Xbox Wireless Adapter
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02fe", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="0719", MODE="0666"

    # PlayStation Controllers (DualShock 4, DualSense)
    SUBSYSTEM=="usb", ATTR{idVendor}=="054c", ATTR{idProduct}=="05c4", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="054c", ATTR{idProduct}=="09cc", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="054c", ATTR{idProduct}=="0ce6", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="054c", ATTR{idProduct}=="0df2", MODE="0666"

    # Nintendo Switch Pro Controller
    SUBSYSTEM=="usb", ATTR{idVendor}=="057e", ATTR{idProduct}=="2009", MODE="0666"

    # 8BitDo Controllers
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", MODE="0666"

    # Generic game controllers - set correct permissions
    KERNEL=="js[0-9]*", MODE="0666"
    KERNEL=="event[0-9]*", SUBSYSTEM=="input", MODE="0666", GROUP="input"

    # Reload input driver on hotplug for stability
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="js[0-9]*", RUN+="${pkgs.systemd}/bin/udevadm trigger --action=change"
  '';

  # ========================================
  # SYSTEMD SERVICE FOR CONTROLLER AUTO-CONNECT
  # ========================================

  # Off critical path: runs after graphical.target so it never blocks
  # userspace boot. No leading sleep — bluetoothctl wait-loop is enough.
  systemd.services.bluetooth-controller-connect = {
    description = "Auto-connect paired Bluetooth controllers";
    after = [ "bluetooth.service" "bluetooth.target" "graphical.target" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "graphical.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "bt-connect" ''
        for i in {1..10}; do
          ${pkgs.bluez}/bin/bluetoothctl show | grep -q "Powered: yes" && break
          sleep 1
        done

        ${pkgs.bluez}/bin/bluetoothctl devices Paired | while read -r _ mac name; do
          ${pkgs.bluez}/bin/bluetoothctl connect "$mac" &
        done
        wait
      '';
      RemainAfterExit = false;
    };
  };

  # Only reconnect after sleep/hibernate, not periodically
  systemd.services.bluetooth-controller-resume = {
    description = "Reconnect Bluetooth controllers after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = pkgs.writeShellScript "bt-resume" ''
        # Restart Bluetooth to clear stale connections
        ${pkgs.systemd}/bin/systemctl restart bluetooth.service
        sleep 2

        # Connect to paired devices
        ${pkgs.bluez}/bin/bluetoothctl devices Paired | while read -r _ mac name; do
          echo "Reconnecting after resume: $name ($mac)"
          ${pkgs.bluez}/bin/bluetoothctl connect "$mac" &
        done
        wait
      '';
    };
  };

  # ========================================
  # KERNEL CONFIGURATION FOR CONTROLLERS
  # ========================================
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      xpadneo
      xone
    ];

    # Kernel modules to load
    kernelModules = [
      "uinput"
      "hid-generic"
      "hid-sony"
      "hid-microsoft"
      "hid-nintendo"
    ];

    extraModprobeConfig = ''
      # Fix ERTM for Xbox Bluetooth controllers
      options bluetooth disable_ertm=Y

      # xpadneo options for better stability
      options xpadneo disable_deadzones=0
      options xpadneo trigger_rumble_mode=0

      # Increase HID timeout for slow controllers
      options usbhid mousepoll=4
    '';
  };


  # Ensure user is in input group for controller access
  users.groups.input = {};
}
