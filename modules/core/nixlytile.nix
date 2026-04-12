{ pkgs, pkgs-unstable, lib, ... }:

let
  nixlytile = pkgs-unstable.nixlytile;

  # Launcher factory: takes the original wrapProgram wrapper script from the
  # nixlytile derivation, replaces the exec target with the capability-wrapped
  # binary, and sets EGL/GL vendor paths so Xwayland can find NVIDIA's EGL via
  # libepoxy.
  #
  # Note: LD_LIBRARY_PATH is stripped by the kernel for capability-wrapped
  # binaries (AT_SECURE), so __EGL_VENDOR_LIBRARY_DIRS is the one that
  # actually survives the cap-wrapper; LD_LIBRARY_PATH is a fallback for
  # Xwayland GL clients.
  #
  # `name` — basename of the produced binary in $out/bin/
  mkLauncher = { name }:
    pkgs.runCommand "nixlytile-launcher-${name}" {} ''
      mkdir -p $out/bin
      sed 's|"${nixlytile}/bin/.nixlytile-wrapped"|"/run/wrappers/bin/nixlytile-cap"|' \
        ${nixlytile}/bin/nixlytile > $out/bin/${name}
      sed -i '/^exec /i export __EGL_VENDOR_LIBRARY_DIRS="/run/opengl-driver/share/glvnd/egl_vendor.d''${__EGL_VENDOR_LIBRARY_DIRS:+:$__EGL_VENDOR_LIBRARY_DIRS}"' \
        $out/bin/${name}
      sed -i '/^exec /i export LD_LIBRARY_PATH="${pkgs.libglvnd}/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' \
        $out/bin/${name}
      chmod +x $out/bin/${name}
    '';

  nixlytile-launcher = mkLauncher { name = "nixlytile"; };

  # Display-manager session entry
  sessionDesktops = pkgs.runCommand "nixlytile-session-desktops" {} ''
    mkdir -p $out/share/wayland-sessions

    cat > $out/share/wayland-sessions/nixlytile.desktop <<'EOF'
    [Desktop Entry]
    Name=Nixly
    Comment=Tiling Wayland compositor (Vulkan renderer)
    Exec=nixlytile
    Type=Application
    EOF
  '';

  # Session package: launcher + desktop file + data from original package
  nixlytile-session = pkgs.symlinkJoin {
    name = "nixlytile-session";
    paths = [
      nixlytile-launcher
      sessionDesktops
    ];
    passthru.providedSessions = [ "nixlytile" ];
    postBuild = ''
      mkdir -p $out/share
      ln -sf ${nixlytile}/share/nixlytile $out/share/nixlytile
      ln -sf ${nixlytile}/share/man $out/share/man
    '';
  };
in {
  # Capability-wrapped binary at /run/wrappers/bin/nixlytile-cap
  # Named nixlytile-cap (not nixlytile) to avoid shadowing the launcher
  # script in /run/current-system/sw/bin/nixlytile — /run/wrappers/bin
  # comes first in PATH, so a same-named wrapper would bypass the
  # wrapProgram PATH setup (fd, findutils, swaybg, etc.).
  security.wrappers.nixlytile-cap = {
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
