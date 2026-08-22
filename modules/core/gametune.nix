{ pkgs, ... }:

let
  saveFile = "/run/nixly-gametune.swappiness";
  dpmFile = "/run/nixly-gametune.dpm";
  oomStateDir = "/run/nixly-gametune";

  start = pkgs.writeShellScript "nixly-gametune-start" ''
    set -u
    export PATH=${pkgs.coreutils}/bin

    # Lower swappiness while a game runs; zram compression steals cycles from
    # the game cores. The real value is saved so ExecStop restores it.
    cat /proc/sys/vm/swappiness > ${saveFile} || true
    echo 10 > /proc/sys/vm/swappiness || true

    # One explicit compaction, replacing the background one perf.nix disables.
    echo 1 > /proc/sys/vm/compact_memory || true

    # AMD DPM to high; a no-op where the sysfs file does not exist.
    : > ${dpmFile}
    for f in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
      [ -e "$f" ] || continue
      printf '%s %s\n' "$f" "$(cat "$f")" >> ${dpmFile}
      echo high > "$f" || true
    done

    # PM QoS 0 µs keeps the CPU out of deep C-states for as long as fd 3 stays
    # open, hence the exec sleep; the existence check keeps VMs from failing.
    if [ -e /dev/cpu_dma_latency ]; then
      exec 3>/dev/cpu_dma_latency
      head -c4 /dev/zero >&3
    fi
    exec sleep infinity
  '';

  stop = pkgs.writeShellScript "nixly-gametune-stop" ''
    set -u
    export PATH=${pkgs.coreutils}/bin
    if [ -r ${saveFile} ]; then
      cat ${saveFile} > /proc/sys/vm/swappiness || true
      rm -f ${saveFile}
    fi
    if [ -r ${dpmFile} ]; then
      while read -r path value; do
        [ -n "$path" ] && echo "$value" > "$path" 2>/dev/null
      done < ${dpmFile}
      rm -f ${dpmFile}
    fi
  '';

  # OOM protection for the game tree. Lowering oom_score_adj needs
  # CAP_SYS_RESOURCE, so the compositor cannot do it itself. The whole tree
  # matters, not just the leader: a Proton game is a wine server plus several
  # helper processes, and killing any of them ends the session just as
  # effectively. Every old value is saved so unprotect restores it.
  protect = pkgs.writeShellScript "nixly-gameprio-protect" ''
    set -u
    export PATH=${pkgs.coreutils}/bin:${pkgs.gawk}/bin

    pid=''${1:-}
    [ -n "$pid" ] || { echo "usage: $0 <pid>" >&2; exit 1; }
    [ -d "/proc/$pid" ] || exit 0

    state=${oomStateDir}/oom.$pid
    : > "$state"

    # One pass over /proc, repeated until no new descendant is picked up,
    # so children that appear below an already-matched parent are caught.
    matched=" $pid "
    pass=0
    while [ "$pass" -lt 3 ]; do
      pass=$((pass + 1))
      for proc in /proc/[0-9]*; do
        p=''${proc#/proc/}
        case "$matched" in *" $p "*) continue ;; esac
        ppid=$(awk '/^PPid:/ {print $2; exit}' "$proc/status" 2>/dev/null) || continue
        [ -n "''${ppid:-}" ] || continue
        case "$matched" in *" $ppid "*) matched="$matched$p " ;; esac
      done
    done

    for p in $matched; do
      [ -f "/proc/$p/oom_score_adj" ] || continue
      old=$(cat "/proc/$p/oom_score_adj" 2>/dev/null) || continue
      printf '%s %s\n' "$p" "$old" >> "$state"
      echo -900 > "/proc/$p/oom_score_adj" 2>/dev/null || true
    done
  '';

  unprotect = pkgs.writeShellScript "nixly-gameprio-unprotect" ''
    set -u
    export PATH=${pkgs.coreutils}/bin

    pid=''${1:-}
    [ -n "$pid" ] || { echo "usage: $0 <pid>" >&2; exit 1; }
    state=${oomStateDir}/oom.$pid
    [ -f "$state" ] || exit 0

    while read -r old_pid old_value; do
      [ -f "/proc/$old_pid/oom_score_adj" ] || continue
      echo "$old_value" > "/proc/$old_pid/oom_score_adj" 2>/dev/null
    done < "$state"
    rm -f "$state"
  '';
in
{
  # The privileged half of nixlytile's game mode; everything else it used to
  # touch is now static in boot.nix, perf.nix and system_services.nix.
  systemd.services.nixly-gametune = {
    description = "Low-latency tuning while a game is running";
    serviceConfig = {
      Type = "simple";
      ExecStart = start;
      ExecStop = stop;
      Restart = "no";
    };
  };

  # Per-game OOM protection; the game PID is the instance name.
  systemd.services."nixly-gameprio@" = {
    description = "OOM protection for game PID %i";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${protect} %i";
      ExecStop = "${unprotect} %i";
      # That is where the saved oom_score_adj values live.
      RuntimeDirectory = "nixly-gametune";
      RuntimeDirectoryPreserve = "yes";
    };
  };

  # nixlytile starts and stops the units when ultra game mode kicks in.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.isInGroup("gamemode")) {
        var unit = action.lookup("unit");
        if (unit && (unit == "nixly-gametune.service" ||
            unit.indexOf("nixly-gameprio@") == 0)) {
          return polkit.Result.YES;
        }
      }
    });
  '';
}
