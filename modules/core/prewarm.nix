{ pkgs, ... }:

let
  # Gate for timer-prewarm: hopp over når et spill kjører (vmtouch av
  # titalls GB ville kastet spillets working set ut av page cache — verre
  # enn kald cache) eller når maskinen er opptatt med annet.
  # Exit 1 = skip (ExecCondition hopper over uten failure).
  prewarmGate = pkgs.writeShellScript "nixly-prewarm-gate" ''
    set -u
    # Spill aktivt? nixly-gametune startes av nixlytile ved game mode;
    # feral gamemoded har klienter når gamewrap har lansert et spill.
    if ${pkgs.systemd}/bin/systemctl is-active -q nixly-gametune.service; then
      exit 1
    fi
    if ${pkgs.procps}/bin/pgrep -x gamemoded >/dev/null 2>&1; then
      clients=$(${pkgs.systemd}/bin/busctl --user get-property \
        com.feralinteractive.GameMode /com/feralinteractive/GameMode \
        com.feralinteractive.GameMode ClientCount 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '{print $2}')
      [ "''${clients:-0}" -gt 0 ] && exit 1
    fi
    # Maskin opptatt? 1-min load over halvparten av kjernene = noe tungt
    # kjører (kompilering, render); idle-klassene hjelper ikke mot
    # cache-eviction, saa vent heller til neste tick.
    ncpu=$(${pkgs.coreutils}/bin/nproc)
    ${pkgs.gawk}/bin/awk -v n="$ncpu" '{exit ($1 > n/2) ? 1 : 0}' /proc/loadavg \
      || exit 1
    # Minnepress? Under 25% ledig betyr at oppvarming bare resirkulerer
    # page cache uten aa bli liggende.
    ${pkgs.gawk}/bin/awk '/MemTotal/{t=$2} /MemAvailable/{a=$2}
      END{exit (a < t/4) ? 1 : 0}' /proc/meminfo || exit 1
    exit 0
  '';

  # Timer-prewarm: launch-kjeden + ALLE installerte spill i alle Steam-
  # libraries. -m 512M hopper over gigant-paks (streames uansett under
  # loading screen) — det som varmes er exe/dll/so/config/smaa-assets,
  # dvs. det spillet leser foer og rett etter "Play". Gaten re-sjekkes
  # mellom hvert spill: starter et spill midt i loepet, avbrytes resten.
  prewarmGamesScript = pkgs.writeShellScript "nixly-prewarm-games" ''
    set -u
    VMTOUCH=${pkgs.vmtouch}/bin/vmtouch

    warm() {
      [ -e "$1" ] && "$VMTOUCH" -t -q -m 512M "$1" 2>/dev/null || true
    }

    S="$HOME/.local/share/Steam"
    [ -d "$S" ] || S="$HOME/.steam/steam"
    [ -d "$S" ] || exit 0

    # Alle library-mapper fra libraryfolders.vdf + hoved-library.
    libs="$S"
    vdf="$S/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then
      extra=$(${pkgs.gnugrep}/bin/grep -oP '"path"\s+"\K[^"]+' "$vdf" 2>/dev/null || true)
      libs=$(printf '%s\n%s\n' "$libs" "$extra" | ${pkgs.coreutils}/bin/sort -u)
    fi

    for lib in $libs; do
      for d in "$lib"/steamapps/common/*/; do
        [ -d "$d" ] || continue
        # Re-sjekk gaten mellom hvert spill — abort om spill startet
        # eller minnet er brukt opp underveis.
        ${prewarmGate} || exit 0
        warm "$d"
      done
    done
  '';


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

  # Idle-utloest re-varming: launch-kjeden (kastes ut av page cache etter
  # tunge jobber) + alle installerte spill. Startes av swayidle (autostart
  # i nixlytile-config) etter 5 min uten input, og STOPPES av swayidle sin
  # resume-hook i samme oeyeblikk musen/tastaturet roeres — systemctl stop
  # dreper vmtouch midt i loepet. ExecCondition hopper stille over naar
  # gaten sier nei (spill aktivt, hoey load, minnepress).
  systemd.user.services.nixly-prewarm-games = {
    description = "Preload Steam launch chain and installed games into page cache";
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = "${prewarmGate}";
      ExecStart = [ "${prewarmScript}" "${prewarmGamesScript}" ];
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  environment.systemPackages = [ pkgs.vmtouch pkgs.swayidle ];
}
