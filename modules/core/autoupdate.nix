{ pkgs, ... }:

{
  # Owned by total: root has no ssh key and cannot reach private flake inputs.
  systemd.tmpfiles.rules = [
    "d /var/lib/nixly-update 0755 total users -"
    "d /var/cache/nixly-update 0700 total users -"
  ];

  # Bumps pins in a copy of the repo and builds the whole closure there; only a
  # successful build bumps the real flake.lock and raises the pending flag.
  systemd.services.nixly-update-check = {
    description = "NixlyOS update check + pre-build validation";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.git pkgs.nix pkgs.rsync pkgs.bash pkgs.gawk ];
    serviceConfig = {
      Type = "oneshot";
      User = "total";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      set -euo pipefail
      repo=/var/cache/nixly-update/repo
      rsync -a --delete /home/total/.nixlyos/ "$repo"/
      cd "$repo"

      # Run in the copy, so a hardware change is validated by the pre-build too.
      bash "$repo/scripts/detect-hw.sh" "$repo"

      # Keep the old Proton-GE pin if the bump fails.
      bash pkgs/proton-ge/bump.sh || true

      nix flake update --flake "$repo"

      # If anything fails to build we stop here and never touch the real repo.
      nix build "$repo#nixosConfigurations.nixlyos.config.system.build.toplevel" \
        --out-link /var/lib/nixly-update/result

      new=$(readlink -f /var/lib/nixly-update/result)
      boot=$(readlink -f /nix/var/nix/profiles/system)
      if [ "$new" = "$boot" ]; then
        rm -f /var/lib/nixly-update/pending /var/lib/nixly-update/result
        exit 0
      fi

      # Validated, so bump the real repo.
      cp "$repo/flake.lock" /home/total/.nixlyos/flake.lock
      cp "$repo/modules/core/default.nix" /home/total/.nixlyos/modules/core/default.nix
      rsync -a "$repo/pkgs/proton-ge/" /home/total/.nixlyos/pkgs/proton-ge/

      echo "$new" > /var/lib/nixly-update/pending
    '';
  };

  systemd.timers.nixly-update-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "18:00";
      Persistent = false;          # 18:00 only, never a catch-up run at boot
      RandomizedDelaySec = "10min";
    };
  };

  # Triggered by the tray icon or the 04:00 timer; builds nothing new, since the
  # validated closure is already in the store.
  systemd.services.nixly-update-apply = {
    description = "NixlyOS apply pre-validated update (next boot)";
    path = [ pkgs.nix ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      [ -f /var/lib/nixly-update/pending ] || exit 0
      new=$(cat /var/lib/nixly-update/pending)
      # No new eval here, so root needs neither network nor ssh access.
      nix-env -p /nix/var/nix/profiles/system --set "$new"
      "$new"/bin/switch-to-configuration boot
      rm -f /var/lib/nixly-update/pending /var/lib/nixly-update/result
    '';
  };

  # Only fires if the machine is actually on at 04:00; no catch-up at boot.
  systemd.timers.nixly-update-apply = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "04:00";
  };

  # Lets total start the activation without a password.
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
