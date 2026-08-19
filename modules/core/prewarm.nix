{ pkgs, ... }:

let
  # Skip prewarm (exit 1) when a game runs or the box is busy.
  prewarmGate = pkgs.writeShellScript "nixly-prewarm-gate" ''
    set -u
    # Game active?
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
    # Busy? 1-min load over half the cores means something heavy runs.
    ncpu=$(${pkgs.coreutils}/bin/nproc)
    ${pkgs.gawk}/bin/awk -v n="$ncpu" '{exit ($1 > n/2) ? 1 : 0}' /proc/loadavg \
      || exit 1
    # Memory pressure? Under 25 % free the warmed pages just get evicted.
    ${pkgs.gawk}/bin/awk '/MemTotal/{t=$2} /MemAvailable/{a=$2}
      END{exit (a < t/4) ? 1 : 0}' /proc/meminfo || exit 1
    exit 0
  '';

  # Warm the launch chain plus every installed game in every Steam library.
  prewarmGamesScript = pkgs.writeShellScript "nixly-prewarm-games" ''
    set -u
    VMTOUCH=${pkgs.vmtouch}/bin/vmtouch

    warm() {
      [ -e "$1" ] && "$VMTOUCH" -t -q -m 512M "$1" 2>/dev/null || true
    }

    S="$HOME/.local/share/Steam"
    [ -d "$S" ] || S="$HOME/.steam/steam"
    [ -d "$S" ] || exit 0

    # Every library folder from libraryfolders.vdf plus the main one.
    libs="$S"
    vdf="$S/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then
      extra=$(${pkgs.gnugrep}/bin/grep -oP '"path"\s+"\K[^"]+' "$vdf" 2>/dev/null || true)
      libs=$(printf '%s\n%s\n' "$libs" "$extra" | ${pkgs.coreutils}/bin/sort -u)
    fi

    # Priority each round: two most recently played plus the newest LastUpdated.
    manifests() {
      for lib in $libs; do
        for m in "$lib"/steamapps/appmanifest_*.acf; do
          [ -f "$m" ] || continue
          ${pkgs.gawk}/bin/awk -F'"' -v lib="$lib" '
            /"installdir"/  { d = $4 }
            /"LastUpdated"/ { u = $4 }
            /"LastPlayed"/  { p = $4 }
            END {
              if (d != "" && d !~ /^(Proton|SteamLinuxRuntime|Steamworks)/)
                printf "%d|%d|%s/steamapps/common/%s\n", p, u, lib, d
            }' "$m"
        done
      done
    }

    prio=$(manifests)
    if [ -n "$prio" ]; then
      played=$(printf '%s\n' "$prio" | ${pkgs.coreutils}/bin/sort -t'|' -k1,1 -rn \
        | ${pkgs.gawk}/bin/awk -F'|' '$1 > 0 { print $3 }' | ${pkgs.coreutils}/bin/head -2)
      installed=$(printf '%s\n' "$prio" | ${pkgs.coreutils}/bin/sort -t'|' -k2,2 -rn \
        | ${pkgs.gawk}/bin/awk -F'|' 'NR == 1 { print $3 }')
      # Here-string, not a pipe: a subshell would swallow the gate's exit.
      prio_dirs=$(printf '%s\n%s\n' "$played" "$installed" \
        | ${pkgs.gawk}/bin/awk 'NF && !seen[$0]++')
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        ${prewarmGate} || exit 0
        warm "$d"
      done <<< "$prio_dirs"
    fi

    # Cursor holds the last finished dir so the next round resumes instead of restarting.
    CURSOR="''${XDG_CACHE_HOME:-$HOME/.cache}/nixly-prewarm-games.cursor"
    last=$(${pkgs.coreutils}/bin/cat "$CURSOR" 2>/dev/null || true)
    skip=0
    [ -n "$last" ] && skip=1

    for lib in $libs; do
      for d in "$lib"/steamapps/common/*/; do
        [ -d "$d" ] || continue
        # Fast-forward to where the previous round stopped.
        if [ "$skip" = 1 ]; then
          [ "$d" = "$last" ] && skip=0
          continue
        fi
        # Re-check the gate between games.
        ${prewarmGate} || exit 0
        warm "$d"
        printf '%s\n' "$d" > "$CURSOR"
      done
    done
    ${pkgs.coreutils}/bin/rm -f "$CURSOR"
  '';


  # Pull launch-critical files into page cache at login, at IO/CPU idle priority.
  pagecacheScript = pkgs.writeShellScript "nixly-pagecache" ''
    set -u
    VMTOUCH=${pkgs.vmtouch}/bin/vmtouch

    # -m 512M skips huge paks; they stream during the loading screen anyway.
    warm() {
      [ -e "$1" ] && "$VMTOUCH" -t -q -m 512M "$1" 2>/dev/null || true
    }

    # Steam launch chain: client, pressure-vessel runtime, Proton.
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
      # Newest GE-Proton, the one autoconfig picks.
      ge=$(ls -dt "$S"/compatibilitytools.d/GE-Proton* 2>/dev/null | head -1)
      [ -n "$ge" ] && warm "$ge"
      for d in "$S"/steamapps/common/Proton*; do
        warm "$d"
      done
      # Warm shader caches avoid recompilation on launch.
      warm "$S/steamapps/shadercache"
    fi
    warm "$HOME/.cache/mesa_shader_cache"
    warm "$HOME/.cache/mesa_shader_cache_db"
    warm "$HOME/.cache/nvidia/GLCache"
    warm "$HOME/.nv/GLCache"

    # Full store closure for instant-open apps, only on roomy machines.
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

  # Replays downloaded Vulkan pipeline caches into the driver caches, and provides
  # the `readahead <appid>` the compositor calls on Play.
  prewarm = pkgs.writeShellApplication {
    name = "nixly-prewarm";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
      gnugrep
      inotify-tools
      procps
      util-linux
      vulkan-tools
    ];
    text = builtins.readFile ./nixly-prewarm;
  };
in
{
  # steam-run gives fossilize_replay its FHS env; prewarm must sit on system PATH.
  environment.systemPackages = [
    prewarm
    pkgs.steam-run
    pkgs.vmtouch
    pkgs.swayidle
  ];

  # User services, not system: they need $HOME, and nixlytile only reaches default.target.
  systemd.user.services.nixly-pagecache = {
    description = "Preload launch-critical files into page cache";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pagecacheScript;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  # Idle re-warm: swayidle starts this after 5 min and stops it on the first input.
  systemd.user.services.nixly-prewarm-games = {
    description = "Preload Steam launch chain and installed games into page cache";
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = "${prewarmGate}";
      ExecStart = [ "${pagecacheScript}" "${prewarmGamesScript}" ];
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
      # Cap so the kernel reclaims prewarm's own pages instead of the session's.
      MemoryHigh = "8G";
    };
  };

  # Full shader-replay pass; the script SIGSTOPs fossilize itself when a game starts.
  systemd.user.services.nixly-prewarm = {
    description = "nixlytile Steam shader prewarm";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${prewarm}/bin/nixly-prewarm run";
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "batch";
    };
    # fossilize_replay via steam-run and vendor Vulkan ICDs.
    path = [ "/run/current-system/sw" ];
  };

  # inotify on each library's shadercache; replays new pipeline caches as they land.
  systemd.user.services.nixly-prewarm-watch = {
    description = "nixlytile Steam shader prewarm install watcher";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${prewarm}/bin/nixly-prewarm watch";
      Restart = "on-failure";
      RestartSec = 30;
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "batch";
    };
    path = [ "/run/current-system/sw" ];
  };
}
