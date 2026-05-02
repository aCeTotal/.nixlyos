{ config, lib, pkgs, ... }:

{
  # ── Firewall ──────────────────────────────────────────────────────
  networking.firewall.enable = true;

  # Deluge BitTorrent
  networking.firewall.allowedTCPPorts = [ 6881 ];
  networking.firewall.allowedUDPPorts = [ 6881 ];
  networking.firewall.allowedTCPPortRanges = [ { from = 57000; to = 57010; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 57000; to = 57010; } ];

  # ── AppArmor (MAC) ───────────────────────────────────────────────
  security.apparmor.enable = false;

  # ── Audit ─────────────────────────────────────────────────────────
  security.auditd.enable = true;

  # ── Firejail (applikasjonssandboxing) ─────────────────────────────
  programs.firejail.enable = true;

  # ── USBGuard (blokkerer ukjente USB-enheter) ──────────────────────
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "allow";   # tillat enheter tilkoblet ved boot
    insertedDevicePolicy = "apply-policy";
    rules = ''
      # Tillat standard HID-enheter (tastatur/mus)
      allow with-interface one-of { 03:*:* }

      # Tillat masselagring (USB-disker) - fjern denne linjen for strengere sikkerhet
      allow with-interface one-of { 08:*:* }

      # Tillat USB-huber
      allow with-interface one-of { 09:*:* }

      # Tillat Xbox-kontrollere (Microsoft)
      allow id 045e:*:* with-interface one-of { ff:*:* 03:*:* }

      # Tillat generiske gamepads/joysticks (HID gamepad subclass)
      allow with-interface one-of { 03:00:05 }

      # Tillat andre vanlige kontroller-produsenter
      # Sony (PlayStation)
      allow id 054c:*:* with-interface one-of { 03:*:* ff:*:* }
      # Nintendo
      allow id 057e:*:* with-interface one-of { 03:*:* ff:*:* }
      # Valve (Steam Controller/Deck)
      allow id 28de:*:* with-interface one-of { 03:*:* ff:*:* }
      # 8BitDo
      allow id 2dc8:*:* with-interface one-of { 03:*:* ff:*:* }

      # Blokker alt annet som standard
    '';
  };

  # ── Automatiske sikkerhetsoppdateringer ───────────────────────────
  system.autoUpgrade = {
    enable = true;
    flake = "/home/total/.nixlyos#nixlyos";
    allowReboot = false;
    dates = "04:00";
    randomizedDelaySec = "30min";
    # persistent=false: skip missed runs instead of firing nixos-rebuild
    # right after boot (multi-minute CPU/IO storm during early desktop).
    persistent = false;
  };
}
