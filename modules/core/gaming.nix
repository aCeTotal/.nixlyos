{ config, lib, pkgs, ... }:

{
  imports = [ ./steam ];

  # Tillat brukere i `gamemode`-gruppa å starte/stoppe ananicy-cpp.service uten
  # passord — gamemode start/end-skript pauser ananicy under spill og restarter
  # etterpå (unngår konflikt mellom ananicy's renice og gamemode's renice).
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "ananicy-cpp.service" &&
          subject.isInGroup("gamemode")) {
        return polkit.Result.YES;
      }
    });
  '';

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 0;               # Real-time I/O priority
        inotify = 131072;         # Upstream default; Unity-spill og store mods treffer 8192-taket
        inhibit_screensaver = 1;
        softrealtime = "auto";
        reaper_freq = 5;          # Check for game exit every 5s
        # desiredgov/defaultgov fjernet: governor eies naa av
        # perf.nix (performance, alltid). defaultgov="powersave" lot
        # dessuten CPU-en staa igjen i powersave etter hvert spill.
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        nv_powermizer_mode = 1;   # Prefer max performance for Nvidia
        nv_core_clock_mhz_offset = 0;
        nv_mem_clock_mhz_offset = 0;
        amd_performance_level = "high"; # AMD DPM → max under spill (no-op på NVIDIA/Intel)
      };
      cpu = {
        park_cores = "no";
        # pin_cores = "no": nixlytile eier CPU-affinitet (SMT-korrekt split,
        # compositor paa fysisk kjerne 0, spill paa resten). To skrivere ga
        # race — feral sin maske vant tilfeldig avhengig av rekkefoelge.
        pin_cores = "no";
      };
      custom = {
        # Ingen notify-send her: nixlytile viser sin egen "Game Mode On"
        # sammen med start-animasjonen. En dunst-boks i tillegg ga dobbelt
        # varsel, i gammel stil, flere ganger per spillstart.
        start = "${pkgs.writeShellScript "gamemode-start" ''
          ${pkgs.systemd}/bin/systemctl stop ananicy-cpp.service || true
        ''}";
        end = "${pkgs.writeShellScript "gamemode-end" ''
          ${pkgs.systemd}/bin/systemctl start ananicy-cpp.service || true
        ''}";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    (geforce-now.override { browserCommand = "google-chrome-stable"; })
    steamcmd
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
        # Interval == Window (30/30) ga 100 % scan-duty — radioen scannet
        # KONTINUERLIG saa lenge en paret LE-enhet var utenfor rekkevidde
        # (jevn hci0-kworker-last). 60/30 = 50 % duty; en kontroller som
        # slaas paa oppdages fortsatt innen ~100 ms.
        ScanIntervalAutoConnect = 60;
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

    # Valve Steam Controller (legacy + Steam Controller 2 / Frame).
    # steam-hardware-modulen leverer hovedreglene; dette er fallback med
    # uaccess-tag så aktiv logind-sesjon alltid får tilgang (USB + hidraw +
    # Bluetooth-LE). Dekker alle Valve-PIDer (1101/1102/1142/1201/1205/12xx
    # samt nye Frame-PIDer).
    SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0660", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0660", TAG+="uaccess"
    KERNEL=="hidraw*", KERNELS=="*28DE:*", MODE="0660", TAG+="uaccess"

    # Generic game controllers. 0660+input-gruppe i stedet for 0666:
    # world-readable event-noder lot enhver prosess sniffe tastaturet.
    # uaccess-tag gir aktiv logind-sesjon ACL uansett gruppe.
    KERNEL=="js[0-9]*", MODE="0660", GROUP="input", TAG+="uaccess"
    KERNEL=="event[0-9]*", SUBSYSTEM=="input", MODE="0660", GROUP="input", TAG+="uaccess"

    # ntsync (kernel 6.14+): Wine/Proton NT-synkprimitiver i kernel — bedre
    # frame-pacing enn fsync/futex-waitv i CPU-tunge titler. GE-Proton tar
    # den i bruk naar /dev/ntsync er tilgjengelig (se steam/gamewrap.nix).
    KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
  '';

  # ========================================
  # SYSTEMD SERVICE FOR CONTROLLER AUTO-CONNECT
  # ========================================

  # Async: Type=simple so service is "active" once forked. Does NOT block
  # graphical.target's wait. wantedBy bluetooth.target so it ties to BT
  # lifecycle, not boot. Saved ~10s of synthetic graphical.target wait.
  systemd.services.bluetooth-controller-connect = {
    description = "Auto-connect paired Bluetooth controllers";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "bluetooth.target" ];

    serviceConfig = {
      Type = "simple";
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
    ]
    # ntsync: NT-synkprimitiver for Wine/Proton — bare paa kerneler som
    # faktisk har driveren (fullverdig fra 6.14), ellers feiler
    # systemd-modules-load paa fallback-kernelen.
    ++ lib.optional
      (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14")
      "ntsync";

    extraModprobeConfig = ''
      # Fix ERTM for Xbox Bluetooth controllers
      options bluetooth disable_ertm=Y

      # xpadneo options for better stability
      options xpadneo disable_deadzones=0
      options xpadneo trigger_rumble_mode=0
    '';
    # usbhid mousepoll=4 fjernet: den KAPPET polling til 250 Hz for alle
    # USB-mus (1000 Hz gaming-mus fikk +3 ms input-latency). Default (0)
    # bruker enhetens egen intervall-deskriptor.
  };


  # Ensure user is in input group for controller access
  users.groups.input = {};
}
