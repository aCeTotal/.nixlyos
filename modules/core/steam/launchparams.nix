# Per-spill launch-parametre valgt etter GPU-leverandør.
#
# Nøkkel: "<steam-appid>_<vendor>" der vendor er "nvidia" eller "amd".
# nixly-game-wrap (gamewrap.nix) slår opp nøkkelen ved hver spillstart
# (SteamAppId fra Steam + GPU-deteksjon) — riktig variant brukes automatisk,
# maskinen trenger ingen egen config.
#
# Verdien har Steam launch-options-syntaks uten %command%:
#   - Ledende KEY=VAL-tokens blir miljøvariabler for spillet.
#   - Resten legges til som argumenter etter spillbinæren.
#   Eks: "DXVK_ASYNC=1 PROTON_USE_FSYNC=1 -nosplash -skipIntro"
{
  # Arma 3
  "107410_nvidia" = "__GL_THREADED_OPTIMIZATIONS=1 PROTON_USE_FSYNC=1";
  # "107410_amd" = "RADV_PERFTEST=aco PROTON_USE_FSYNC=1";
}
