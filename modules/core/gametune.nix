{ pkgs, ... }:

let
  saveFile = "/run/nixly-gametune.swappiness";
  dpmFile = "/run/nixly-gametune.dpm";

  start = pkgs.writeShellScript "nixly-gametune-start" ''
    set -u
    export PATH=${pkgs.coreutils}/bin

    # Swappiness ned mens spillet kjoerer. zram.nix setter 180 (riktig for
    # zram normalt), men zram-komprimering under spill stjeler CPU-sykluser
    # fra spillkjernene og gir frame-time-spikes. Lagre den faktiske verdien
    # og legg den tilbake i ExecStop — ikke en hardkodet default.
    cat /proc/sys/vm/swappiness > ${saveFile} || true
    echo 10 > /proc/sys/vm/swappiness || true

    # Én eksplisitt kompaktering slik at spillet faar sammenhengende
    # hugepages ved oppstart. perf.nix slaar av bakgrunns-kompaktering
    # (vm.compaction_proactiveness=0) nettopp fordi kcompactd-bursts
    # midt i spill er en stutter-kilde — dette er erstatningen.
    echo 1 > /proc/sys/vm/compact_memory || true

    # AMD DPM til "high" mens spillet kjoerer (no-op paa maskiner uten
    # amdgpu — fila finnes ikke). Vendor-agnostisk: NVIDIA/Intel har ingen
    # tilsvarende sysfs-knapp som er trygg aa tvinge her, de haandteres av
    # driver/compositor.
    : > ${dpmFile}
    for f in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
      [ -e "$f" ] || continue
      printf '%s %s\n' "$f" "$(cat "$f")" >> ${dpmFile}
      echo high > "$f" || true
    done

    # PM QoS: 0 µs akseptabel wakeup-latency = ingen dype C-states.
    # Constrainten lever saa lenge fd-en er aapen, derfor exec sleep
    # (fd 3 arves over exec) i stedet for en travel loop.
    # Eksistens-sjekk foerst: en feilende redirect i `exec` avslutter et
    # ikke-interaktivt shell, og da ville hele unit'en feile paa maskiner
    # uten cpuidle (VM-er).
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
  # Privilegert halvdel av nixlytile sin game mode. Compositoren kjoerer som
  # bruker og kan ikke skrive /proc/sys eller /dev/cpu_dma_latency (root 0600),
  # saa disse to knappene var stille no-ops. Alt annet game mode pleide aa
  # forsoeke — THP, nmi_watchdog, split_lock, io-scheduler, governor, IRQ-
  # affinitet — er naa statisk i boot.nix / perf.nix / system_services.nix og
  # trenger ingen runtime-rettigheter.
  systemd.services.nixly-gametune = {
    description = "Low-latency tuning while a game is running";
    serviceConfig = {
      Type = "simple";
      ExecStart = start;
      ExecStop = stop;
      Restart = "no";
    };
  };

  # nixlytile starter/stopper unit'en over systemd naar ultra game mode slaar
  # inn. Samme moenster som ananicy-cpp-regelen i gaming.nix.
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
