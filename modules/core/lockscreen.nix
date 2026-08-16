{ pkgs, ... }:

let
  lockscreen = pkgs.nixly_lockscreen;
  pamService = "nixly-lockscreen";
  idleTimeoutSeconds = 180;
in
{
  environment.systemPackages = [ lockscreen ];

  security.pam.services.${pamService} = {
    text = ''
      auth     sufficient ${pkgs.linux-pam}/lib/security/pam_unix.so likeauth try_first_pass
      auth     required   ${pkgs.linux-pam}/lib/security/pam_deny.so
      account  required   ${pkgs.linux-pam}/lib/security/pam_unix.so
      password required   ${pkgs.linux-pam}/lib/security/pam_deny.so
      session  required   ${pkgs.linux-pam}/lib/security/pam_unix.so
    '';
  };

  systemd.user.services.nixly-idled = {
    description = "nixly_lockscreen idle daemon";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    environment = {
      NIXLY_IDLE_TIMEOUT_MS = toString (idleTimeoutSeconds * 1000);
      NIXLY_LOCK_CMD = "${lockscreen}/bin/nixly-lockscreen";
      NIXLY_LOCKSCREEN_PAM_SERVICE = pamService;
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lockscreen}/bin/nixly-idled";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  systemd.services.nixly-lockguard = {
    description = "nixly_lockscreen TTY/sysrq lockdown helper";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-logind.service" ];
    serviceConfig = {
      ExecStart = "${lockscreen}/bin/nixly-lockguard";
      Restart = "always";
      RestartSec = 1;
      User = "root";
      RuntimeDirectory = "nixly-lockguard";
      AmbientCapabilities = [ "CAP_SYS_TTY_CONFIG" "CAP_SYS_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_SYS_TTY_CONFIG" "CAP_SYS_ADMIN" ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateNetwork = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" "@privileged" ];
      ReadWritePaths = [ "/proc/sys/kernel/sysrq" ];
    };
  };

  # Ctrl+Alt+Del skal ikke kunne reboote maskinen.
  systemd.suppressedSystemUnits = [ "ctrl-alt-del.target" ];
}
