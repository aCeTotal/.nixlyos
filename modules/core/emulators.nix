{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── NES / SNES / Game Gear / TurboGrafx-16 / Master System ──
    mesen              # binary: Mesen  (multi-system: NES, SNES, GB, GBC, GBA, SMS, GG, PCE)

    # ── Nintendo 64 ──
    rmg-wayland        # binary: RMG  (mupen64plus + ParaLLEl Vulkan LLE, Qt GUI)

    # ── GameCube / Wii ──
    dolphin-emu        # binary: dolphin-emu

    # ── Game Boy / GBC / GBA ──
    mgba               # binary: mgba

    # ── Nintendo DS ──
    melonds            # binary: melonDS

    # ── Nintendo 3DS ──
    azahar             # binary: azahar  (Citra community fork)

    # ── Wii U ──
    cemu               # binary: cemu

    # ── Nintendo Switch ──
    ryubing            # binary: Ryujinx  (Ryujinx community fork)

    # ── PlayStation 1 / Saturn / TurboGrafx-16 fallback ──
    mednafen           # binary: mednafen  (modules: psx, ss, pce, sms, gg)

    # ── PlayStation 2 ──
    pcsx2              # binary: pcsx2-qt

    # ── PlayStation 3 ──
    rpcs3              # binary: rpcs3

    # ── PSP ──
    ppsspp             # binary: ppsspp

    # ── Xbox (original) ──
    xemu               # binary: xemu

    # ── Xbox 360 ──
    xenia-canary       # binary: xenia_canary

    # ── Genesis / Mega Drive / Master System ──
    blastem            # binary: blastem  (also handles Master System)

    # ── Sega CD / 32X (+ Genesis fallback) ──
    ares               # binary: ares  (multi-system, best for Sega CD and 32X)

    # ── Dreamcast ──
    flycast            # binary: flycast

    # ── Atari 2600 ──
    stella             # binary: stella
  ];
}
