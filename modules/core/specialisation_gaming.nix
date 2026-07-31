{ ... }:

{
  # Egen boot-entry "gaming": identisk system, men uten Spectre/MDS/
  # Retbleed-mitigations (~10-15% perf paa Comet Lake). Default entry
  # (nixlyos) kjoerer med mitigations paa; velg gaming i boot-menyen
  # for spillkvelder.
  specialisation.gaming.configuration = {
    boot.kernelParams = [
      "mitigations=off"
      # Ingen dype C-states: dreper wakeup-latency (frame-time-spikes ved
      # lav CPU-last). Kostnad: hoeyere idle-stroemtrekk/varme — derfor
      # kun i gaming-modus. intel_idle-parameteren er inert paa AMD.
      "intel_idle.max_cstate=1"
      "processor.max_cstate=1"
    ];

    # Maks klokker hele tiden, ikke bare mens gamemode er aktiv (dekker
    # shader-kompilering, menyer og bakgrunnslast mellom oekter).
    powerManagement.cpuFreqGovernor = "performance";
  };
}
