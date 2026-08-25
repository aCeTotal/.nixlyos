{ pkgs, ... }:

{
  # nixlytile's battery popup reads and writes the ACPI platform profile
  # directly (power-profiles-daemon is intentionally disabled — perf.nix
  # owns the governor). sysfs is root-owned, so make the profile file
  # group-writable at boot. ConditionPathExists keeps this a no-op on
  # machines without a platform profile (desktops).
  systemd.services.platform-profile-perms = {
    description = "Make ACPI platform_profile writable for the users group";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/sys/firmware/acpi/platform_profile";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.coreutils}/bin/chgrp users /sys/firmware/acpi/platform_profile"
        "${pkgs.coreutils}/bin/chmod 0664 /sys/firmware/acpi/platform_profile"
      ];
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
