{ pkgs, ... }:

{
  # Root maa kunne lese bruker-eid repo (og byggekopien) via nix' git-
  # fetcher — uten dette feiler fetchTree med "repository path is not
  # owned by current user".
  environment.etc."gitconfig".text = ''
    [safe]
    	directory = /home/total/.nixlyos
    	directory = /var/cache/nixly-update/repo
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/nixly-update 0755 root root -"
    "d /var/cache/nixly-update 0700 root root -"
  ];

  # ── Sjekk + forhaandsbygg (18:00) ─────────────────────────────────
  # Bumper pins i en KOPI av repoet og bygger hele system-closuret der.
  # Bygget er garantien: lykkes det, er alt kompilert og hentet. Foerst
  # da bumpes ekte nixpkgs.txt/flake.lock (som bruker total), resultatet
  # GC-rotes, og pending-flagget faar tray-ikonet til aa vises.
  systemd.services.nixly-update-check = {
    description = "NixlyOS update check + pre-build validation";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.git pkgs.nix pkgs.rsync pkgs.util-linux pkgs.gnused pkgs.bash ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      set -euo pipefail
      repo=/var/cache/nixly-update/repo
      rsync -a --delete /home/total/.nixlyos/ "$repo"/
      cd "$repo"

      # Kanalgrenene (ikke release-*) er Hydra-gatede: de flytter seg foerst
      # naar jobsettet er bygd, saa aa foelge grenhodet garanterer cache.
      rev=$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/nixos-unstable | cut -f1)
      [ -n "$rev" ] || exit 0
      sed -i "s/^unstable=.*/unstable=$rev/" nixpkgs.txt

      # NB: grennavnet maa bumpes manuelt naar neste NixOS-release slippes —
      # nixos-26.05 slutter aa bevege seg naar 26.11 er ute.
      srev=$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/nixos-26.05 | cut -f1)
      [ -n "$srev" ] || exit 0
      sed -i "s/^stable=.*/stable=$srev/" nixpkgs.txt

      # Proton-GE-pin (samme steg som gamle upgrade-aliaset); fortsetter
      # med gammel pin om bump feiler
      bash pkgs/proton-ge/bump.sh || true

      nix flake update --flake "$repo"

      # Full forhaandsbygging — feiler noe som helst, stopper vi her og
      # roerer aldri det ekte repoet
      nix build "$repo#nixosConfigurations.nixlyos.config.system.build.toplevel" \
        --out-link /var/lib/nixly-update/result

      new=$(readlink -f /var/lib/nixly-update/result)
      boot=$(readlink -f /nix/var/nix/profiles/system)
      if [ "$new" = "$boot" ]; then
        rm -f /var/lib/nixly-update/pending /var/lib/nixly-update/result
        exit 0
      fi

      # Validert OK -> bump ekte repo (som total, beholder eierskap)
      for f in nixpkgs.txt flake.lock; do
        runuser -u total -- cp "$repo/$f" "/home/total/.nixlyos/$f"
      done
      runuser -u total -- rsync -a "$repo/pkgs/proton-ge/" /home/total/.nixlyos/pkgs/proton-ge/

      echo "$new" > /var/lib/nixly-update/pending
    '';
  };

  systemd.timers.nixly-update-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "18:00";
      Persistent = false;          # KUN 18:00 — aldri catch-up ved boot
      RandomizedDelaySec = "10min";
    };
  };

  # ── Aktivering ────────────────────────────────────────────────────
  # Kjoeres ved klikk paa tray-ikonet, `upgrade`-aliaset eller 04:00-
  # timeren. Bygger ingenting nytt — repoet peker allerede paa det
  # validerte, alt ligger i store, saa dette er kun eval + bootloader.
  systemd.services.nixly-update-apply = {
    description = "NixlyOS apply pre-validated update (next boot)";
    path = [ pkgs.git pkgs.nix pkgs.nixos-rebuild ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      [ -f /var/lib/nixly-update/pending ] || exit 0
      nixos-rebuild boot --flake /home/total/.nixlyos#nixlyos
      rm -f /var/lib/nixly-update/pending /var/lib/nixly-update/result
    '';
  };

  # 04:00: auto-aktiver KUN om maskinen faktisk er paa. Persistent er
  # bevisst av — var maskinen av kl 04 skjer ingen catch-up ved boot.
  systemd.timers.nixly-update-apply = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "04:00";
  };

  # La bruker total starte aktiveringen uten passord (tray-klikk/alias)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "nixly-update-apply.service" &&
          subject.user == "total") {
        return polkit.Result.YES;
      }
    });
  '';
}
