# Per-game launch parameters keyed by "<appid>_<vendor>", looked up by gamewrap.nix
# on every launch. Leading KEY=VAL tokens become env vars, the rest become args.
{
  # Arma 3
  "107410_nvidia" = "__GL_THREADED_OPTIMIZATIONS=1 PROTON_USE_FSYNC=1";
  # "107410_amd" = "RADV_PERFTEST=aco PROTON_USE_FSYNC=1";
}
