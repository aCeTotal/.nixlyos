{ pkgs, pkgs-unstable, lib, ... }:

let
  nixlytile = pkgs-unstable.nixlytile;

  # Launcher factory: takes the original wrapProgram wrapper script from the
  # nixlytile derivation, replaces the exec target with the capability-wrapped
  # binary, and sets EGL/GL vendor paths so Xwayland can find NVIDIA's EGL via
  # libepoxy. Optionally pins WLR_RENDERER so the display-manager session
  # entries can pick a specific wlroots backend.
  #
  # Note: LD_LIBRARY_PATH is stripped by the kernel for capability-wrapped
  # binaries (AT_SECURE), so __EGL_VENDOR_LIBRARY_DIRS is the one that
  # actually survives the cap-wrapper; LD_LIBRARY_PATH is a fallback.
  #
  # `name`     — basename of the produced binary in $out/bin/
  # `renderer` — null (wlroots auto), "vulkan", or "gles2"
  mkLauncher = { name, renderer ? null }:
    pkgs.runCommand "nixlytile-launcher-${name}" {} ''
      mkdir -p $out/bin
      sed 's|"${nixlytile}/bin/.nixlytile-wrapped"|"/run/wrappers/bin/nixlytile-cap"|' \
        ${nixlytile}/bin/nixlytile > $out/bin/${name}
      sed -i '/^exec /i export __EGL_VENDOR_LIBRARY_DIRS="/run/opengl-driver/share/glvnd/egl_vendor.d''${__EGL_VENDOR_LIBRARY_DIRS:+:$__EGL_VENDOR_LIBRARY_DIRS}"' \
        $out/bin/${name}
      sed -i '/^exec /i export LD_LIBRARY_PATH="${pkgs.libglvnd}/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' \
        $out/bin/${name}
      ${lib.optionalString (renderer != null) ''
        sed -i '/^exec /i export WLR_RENDERER="${renderer}"' $out/bin/${name}
      ''}
      chmod +x $out/bin/${name}
    '';

  nixlytile-launcher      = mkLauncher { name = "nixlytile"; };                              # auto (terminal use)
  nixlytile-launcher-vk   = mkLauncher { name = "nixlytile-vk";   renderer = "vulkan"; };
  nixlytile-launcher-gles = mkLauncher { name = "nixlytile-gles"; renderer = "gles2"; };

  # Two display-manager session entries: Nixly (VK) and Nixly (GLES).
  # The Exec= names match the launcher binaries above (resolved via PATH at
  # session start by the display manager).
  sessionDesktops = pkgs.runCommand "nixlytile-session-desktops" {} ''
    mkdir -p $out/share/wayland-sessions

    cat > $out/share/wayland-sessions/nixlytile-vk.desktop <<'EOF'
    [Desktop Entry]
    Name=Nixly (VK)
    Comment=Tiling Wayland compositor (Vulkan renderer)
    Exec=nixlytile-vk
    Type=Application
    EOF

    cat > $out/share/wayland-sessions/nixlytile-gles.desktop <<'EOF'
    [Desktop Entry]
    Name=Nixly (GLES)
    Comment=Tiling Wayland compositor (GLES2 renderer)
    Exec=nixlytile-gles
    Type=Application
    EOF
  '';

  # Session package: launchers + desktop files + data from original package
  nixlytile-session = pkgs.symlinkJoin {
    name = "nixlytile-session";
    paths = [
      nixlytile-launcher
      nixlytile-launcher-vk
      nixlytile-launcher-gles
      sessionDesktops
    ];
    passthru.providedSessions = [ "nixlytile-vk" "nixlytile-gles" ];
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
