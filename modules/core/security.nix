{ config, lib, pkgs, ... }:

{
  # ── Firewall ──────────────────────────────────────────────────────
  networking.firewall.enable = true;

  # ── Fail2ban ──────────────────────────────────────────────────────
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "48h";
    };
    jails.sshd = {
      settings = {
        enabled = true;
        port = "ssh";
        filter = "sshd";
        maxretry = 3;
      };
    };
  };

  # ── AppArmor (MAC) ───────────────────────────────────────────────
  security.apparmor.enable = true;

  # ── Audit ─────────────────────────────────────────────────────────
  security.audit.enable = true;
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
    persistent = true;
  };
}
