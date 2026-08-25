{ pkgs, ... }:

{
  # nixlytile's battery popup reads and writes the power profile directly
  # via sysfs (power-profiles-daemon is intentionally disabled — perf.nix
  # owns the governor). Backends: ACPI platform_profile, or msi-ec
  # shift_mode on MSI laptops. sysfs is root-owned, so make whichever
  # file exists group-writable at boot; no-op on machines without one.
  systemd.services.platform-profile-perms = {
    description = "Make power-profile sysfs files writable for the users group";
    wantedBy = [ "multi-user.target" ];
    # msi-ec loads via its own autoload service — shift_mode must exist
    # before the perms pass runs
    after = [ "msi-ec-autoload.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "platform-profile-perms" ''
        for f in /sys/firmware/acpi/platform_profile \
                 /sys/devices/platform/msi-ec/shift_mode; do
          if [ -e "$f" ]; then
            ${pkgs.coreutils}/bin/chgrp users "$f"
            ${pkgs.coreutils}/bin/chmod 0664 "$f"
          fi
        done
      '';
    };
  };

  # Let total reboot and power off without a password, even from sessions that
  # are not active on a seat.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions") &&
          subject.user == "total") {
        return polkit.Result.YES;
      }
    });
  '';
}
