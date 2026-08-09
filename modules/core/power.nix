{ ... }:

{
  # La bruker total ta reboot/poweroff uten passord, ogsaa fra sesjoner som
  # ikke er "active" paa et seat (agenter, ssh, tty uten polkit-agent).
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
