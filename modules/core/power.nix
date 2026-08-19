{ ... }:

{
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
