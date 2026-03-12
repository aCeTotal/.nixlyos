{ pkgs, pkgs-stable, lib, ... }:

let
  nixlytile = pkgs-stable.nixlytile;

  # Launcher: takes the original wrapProgram wrapper script,
  # replaces the exec target with the capability-wrapped binary
  nixlytile-launcher = pkgs.runCommand "nixlytile-launcher" {} ''
    mkdir -p $out/bin
    sed 's|"${nixlytile}/bin/.nixlytile-wrapped"|"/run/wrappers/bin/nixlytile"|' \
      ${nixlytile}/bin/nixlytile > $out/bin/nixlytile
    chmod +x $out/bin/nixlytile
  '';

  # Session package: launcher + desktop file + data from original package
  nixlytile-session = pkgs.symlinkJoin {
    name = "nixlytile-session";
    paths = [ nixlytile-launcher ];
    passthru.providedSessions = [ "nixlytile" ];
    postBuild = ''
      mkdir -p $out/share
      ln -sf ${nixlytile}/share/wayland-sessions $out/share/wayland-sessions
      ln -sf ${nixlytile}/share/nixlytile $out/share/nixlytile
      ln -sf ${nixlytile}/share/man $out/share/man
    '';
  };
in {
  # Capability-wrapped binary at /run/wrappers/bin/nixlytile
  security.wrappers.nixlytile = {
    source = "${nixlytile}/bin/.nixlytile-wrapped";
    capabilities = "cap_sys_nice,cap_sys_admin,cap_sys_rawio,cap_dac_override+ep";
    owner = "root";
    group = "users";
  };

  # PAM limits for real-time scheduling and nice values
  security.pam.loginLimits = [
    { domain = "@users"; type = "-"; item = "rtprio"; value = "99"; }
    { domain = "@users"; type = "-"; item = "nice"; value = "-20"; }
    { domain = "@users"; type = "-"; item = "memlock"; value = "unlimited"; }
  ];

  # Launcher in system PATH + display manager session
  environment.systemPackages = [ nixlytile-session ];
  services.displayManager.sessionPackages = [ nixlytile-session ];
}
