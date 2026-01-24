{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };

  hardware.steam-hardware.enable = true;
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 4;
        inotify = 8192;
        inhibit_screensaver = 1;
        softrealtime = "auto";
      };
      gpu = {
        apply_gpu_optimisations = "auto";
        gpu_device = "auto";
        amd_performance_level = "high";
      };
      custom = {
        start = "''";
        end = "''";
      };
    };
  };

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${lib.concatStringsSep ":" [ "$HOME/.steam/root/compatibilitytools.d" "$HOME/.local/share/Steam/compatibilitytools.d" ]}";
  };

  environment.systemPackages = with pkgs; [
    steamcmd
    gamescope
    mangohud
    goverlay
    vkbasalt
    lutris
    heroic
    bottles
    protonup-ng
    protontricks
    wineWowPackages.staging
    winetricks
    dxvk
    vkd3d
    xow_dongle-firmware
    linuxConsoleTools # for jstest and input debugging
    evtest
  ];

  # ========================================
  # CONTROLLER HARDWARE SUPPORT
  # ========================================

  # Xbox controller support
  hardware.xone.enable = true;      # Xbox wireless USB dongle
  hardware.xpadneo.enable = true;   # Xbox Bluetooth (better than manual xpadneo)

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

        # Improved auto-connect settings
        AutoEnable = true;
        FastConnectable = true;
        ReconnectAttempts = 15;
        ReconnectIntervals = "1,2,4,8,16,32,64,128";

        # Controller pairing
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";

        # BLE stability improvements
        MinConnectionInterval = 6;
        MaxConnectionInterval = 9;
        ConnectionLatency = 44;
        SupervisionTimeout = 216;
      };
      Policy = {
        AutoEnable = true;
        ReconnectUUIDs = "00001124-0000-1000-8000-00805f9b34fb,00001200-0000-1000-8000-00805f9b34fb";
      };
      LE = {
        MinAdvertisementInterval = 30;
        MaxAdvertisementInterval = 50;
        AdvertisementDuration = 2;
        ScanIntervalAutoConnect = 30;
        ScanWindowAutoConnect = 30;
      };
      GATT = {
        Cache = "yes";
        Channels = 3;
        KeySize = 0;
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

  # Service runs only once after boot/resume, not periodically
  systemd.services.bluetooth-controller-connect = {
    description = "Auto-connect paired Bluetooth controllers";
    after = [ "bluetooth.service" "bluetooth.target" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = pkgs.writeShellScript "bt-connect" ''
        # Wait for Bluetooth to be ready
        for i in {1..10}; do
          ${pkgs.bluez}/bin/bluetoothctl show | grep -q "Powered: yes" && break
          sleep 1
        done

        # Get paired devices and connect
        ${pkgs.bluez}/bin/bluetoothctl devices Paired | while read -r _ mac name; do
          echo "Attempting to connect: $name ($mac)"
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
