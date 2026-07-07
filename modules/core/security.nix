{ config, lib, pkgs, ... }:

{
  # ── Firewall ──────────────────────────────────────────────────────
  networking.firewall.enable = true;
  # nftables backend: single-transaction rule load, ~hundreds of ms faster
  # than iptables-restore at boot.
  networking.nftables.enable = true;

  # Deluge BitTorrent
  networking.firewall.allowedTCPPorts = [ 6881 ];
  networking.firewall.allowedUDPPorts = [ 6881 ];
  networking.firewall.allowedTCPPortRanges = [ { from = 57000; to = 57010; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 57000; to = 57010; } ];

  # ── AppArmor (MAC) ───────────────────────────────────────────────
  security.apparmor.enable = false;

  # ── Audit ─────────────────────────────────────────────────────────
  # Disabled: with no audit rules configured this was pure logging
  # overhead — ~39% of all journal lines were audit noise (kauditd +
  # auditd write path on every service transition), on a single-user
  # box that also runs mitigations=off.
  security.auditd.enable = false;

  # ── Firejail (applikasjonssandboxing) ─────────────────────────────
  programs.firejail.enable = true;

  # ── USBGuard (blokkerer ukjente USB-enheter) ──────────────────────
  services.usbguard = {
    enable = false;
    presentDevicePolicy = "allow";   # tillat enheter tilkoblet ved boot
    insertedDevicePolicy = "apply-policy";
    # NB: `id` tar VENDOR:PRODUCT (to felt) — den gamle tre-felts
    # formen `id 045e:*:*` ga parse error og lot usbguard.service
    # feile ved hver boot (USB-policy var i praksis avslått).
    # Validert med usbguard-daemon mot dette regelsettet.
    rules = ''
      # Tillat standard HID-enheter (tastatur/mus)
      allow with-interface 03:*:*

      # Tillat masselagring (USB-disker) - fjern denne linjen for strengere sikkerhet
      allow with-interface 08:*:*

      # Tillat USB-huber
      allow with-interface 09:*:*

      # Tillat Xbox-kontrollere (Microsoft)
      allow id 045e:* with-interface one-of { ff:*:* 03:*:* }

      # Tillat generiske gamepads/joysticks (HID gamepad subclass)
      allow with-interface 03:00:05

      # Tillat andre vanlige kontroller-produsenter
      # Sony (PlayStation)
      allow id 054c:* with-interface one-of { 03:*:* ff:*:* }
      # Nintendo
      allow id 057e:* with-interface one-of { 03:*:* ff:*:* }
      # Valve (Steam Controller/Deck)
      allow id 28de:* with-interface one-of { 03:*:* ff:*:* }
      # 8BitDo
      allow id 2dc8:* with-interface one-of { 03:*:* ff:*:* }

      # Blokker alt annet som standard
    '';
  };

  # ── Automatiske sikkerhetsoppdateringer ───────────────────────────
  # Fjernet: nixos-upgrade.service feilet 100% ("repository path is
  # not owned by current user" — root-fetcheren nekter det bruker-eide
  # repoet), så den leverte aldri oppdateringer men brant eval-CPU hver
  # natt og racet manuelle `nixos-rebuild boot`-kjøringer.  Bruk
  # `update`/`upgrade`-aliasene i stedet.
}
