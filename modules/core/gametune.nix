{ pkgs, ... }:

let
  saveFile = "/run/nixly-gametune.swappiness";
  dpmFile = "/run/nixly-gametune.dpm";

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

  # nixlytile starts and stops the unit when ultra game mode kicks in.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "nixly-gametune.service" &&
          subject.isInGroup("gamemode")) {
        return polkit.Result.YES;
      }
    });
  '';
}
