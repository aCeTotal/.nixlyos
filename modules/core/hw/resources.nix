# GENERERT av scripts/detect-hw.sh — ikke rediger manuelt.
# Ren data (ingen NixOS-modul) — leses av nix.nix, zram.nix og boot.nix.
{
  cores = 8;
  memGiB = 31;

  # x86-64 psABI-nivaa: 1 = pre-Nehalem, 2 = SSE4.2/POPCNT,
  # 3 = AVX2/BMI2/FMA, 4 = AVX-512.
  cpuLevel = 3;

  # Utregnet nix-byggparallellisme (se kommentar i scripts/detect-hw.sh).
  maxJobs = 2;
  buildCores = 2;
}
