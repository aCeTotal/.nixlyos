{ pkgs, ... }:

let
  # Alt som ligger i page cache åpnes fra RAM i stedet for disk — det er
  # forskjellen på "instant" og "nesten instant" oppstart. Kjøres ved
  # innlogging med IO/CPU idle-klasse: full fart når maskinen er ledig,
  # viker øyeblikkelig for compositor/innlogging ved contention.
  prewarmScript = pkgs.writeShellScript "nixly-prewarm" ''
    set -u
    VMTOUCH=${pkgs.vmtouch}/bin/vmtouch

    # -t: les inn i page cache. -m 512M: hopp over gigantfiler (spill-
    # paks streames uansett under loading screen). -q: stille.
    warm() {
      [ -e "$1" ] && "$VMTOUCH" -t -q -m 512M "$1" 2>/dev/null || true
    }

    # ── Steam launch-kjeden: klient, pressure-vessel-runtime, Proton ──
    # Dette er filene mellom "Play"-klikk og at spillprosessen kjører.
    S="$HOME/.local/share/Steam"
    [ -d "$S" ] || S="$HOME/.steam/steam"
    if [ -d "$S" ]; then
      warm "$S/ubuntu12_32"
      warm "$S/ubuntu12_64"
      warm "$S/linux32"
      warm "$S/linux64"
      warm "$S/config"
      for d in "$S"/steamapps/common/SteamLinuxRuntime*; do
        warm "$d"
      done
      # Nyeste GE-Proton (den autoconfig velger)
      ge=$(ls -dt "$S"/compatibilitytools.d/GE-Proton* 2>/dev/null | head -1)
      [ -n "$ge" ] && warm "$ge"
      for d in "$S"/steamapps/common/Proton*; do
        warm "$d"
      done
      # Shader-cacher: varm cache = ingen rekompilering, ingen disk-vent
      warm "$S/steamapps/shadercache"
    fi
    warm "$HOME/.cache/mesa_shader_cache"
    warm "$HOME/.cache/mesa_shader_cache_db"
    warm "$HOME/.cache/nvidia/GLCache"
    warm "$HOME/.nv/GLCache"

    # ── Store-closure for programmer som skal åpne instant ──────────
    # Hele runtime-closuren (binær + alle .so-avhengigheter) inn i RAM.
    # Kun på maskiner med romslig minne — på trange bokser gjør cache-
    # thrash mer skade enn nytte.
    avail_kb=$(${pkgs.gnugrep}/bin/grep MemAvailable /proc/meminfo \
      | ${pkgs.gawk}/bin/awk '{print $2}')
    if [ "''${avail_kb:-0}" -gt 8388608 ]; then
      for app in steam google-chrome-stable alacritty dolphin mpv fuzzel; do
        bin=$(command -v "$app" 2>/dev/null) || continue
        store=$(${pkgs.coreutils}/bin/readlink -f "$bin") || continue
        ${pkgs.nix}/bin/nix-store -qR "''${store%/bin/*}" 2>/dev/null \
          | while read -r p; do warm "$p"; done
      done
    fi
  '';
in
{
  # Bruker-service, ikke system: trenger $HOME, og default.target aktiveres
  # ved innlogging (graphical-session.target gjør det ikke i nixlytile-
  # sesjonen). Steam -silent-autostarten (+20s) treffer da varm cache.
  systemd.user.services.nixly-prewarm = {
    description = "Preload launch-critical files into page cache";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = prewarmScript;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  environment.systemPackages = [ pkgs.vmtouch ];
}
