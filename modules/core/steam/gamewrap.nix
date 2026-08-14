{ python3, gamemode, writeScript, writeText, launchParams ? { } }:

# Per-game wrapper injected into every Steam app's LaunchOptions as
# `<this> %command%`. Applies PRIME offload (hybrid-GPU), per-GPU launch
# parameters from launchparams.nix, and chains gamemoderun in front of the
# actual game binary.
#
# Steam stores LaunchOptions as plain text, so the absolute store path is
# baked into every per-app entry; autoconfig.nix re-patches on each launch so
# a new build's path replaces the old one before any game runs.
writeScript "nixly-game-wrap" ''
  #!${python3}/bin/python3
  """Wrap %command% with PRIME offload + per-GPU params + gamemoderun."""
  import json, os, shlex, sys

  GAMEMODERUN = "${gamemode}/bin/gamemoderun"

  # "<appid>_<vendor>" -> "KEY=VAL ... -arg ..." (see launchparams.nix).
  # Separate store file: inlining JSON in a Python string literal breaks on
  # embedded quotes.
  with open("${writeText "nixly-launch-params.json"
      (builtins.toJSON launchParams)}") as _f:
      LAUNCH_PARAMS = json.load(_f)

  def apply_prime_offload():
      # Applied per-game, not to the Steam parent: forcing the Steam UI onto
      # the dGPU makes steamwebhelper's CEF GPU process look up libGLX_nvidia
      # inside the steam-runtime container, where /run/opengl-driver is not
      # bound — CEF then crashes in a respawn loop and the UI never renders.
      # Detection-gated so single-GPU hosts get neither __GLX_VENDOR_LIBRARY_NAME
      # nor DRI_PRIME.
      try:
          renders = [p for p in os.listdir("/sys/class/drm")
                     if p.startswith("renderD")]
      except OSError:
          return
      if len(renders) <= 1:
          return
      if os.path.exists("/proc/driver/nvidia/version"):
          os.environ.setdefault("__NV_PRIME_RENDER_OFFLOAD", "1")
          os.environ.setdefault(
              "__NV_PRIME_RENDER_OFFLOAD_PROVIDER", "NVIDIA-G0")
          os.environ.setdefault("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
          os.environ.setdefault("__VK_LAYER_NV_optimus", "NVIDIA_only")
      else:
          os.environ.setdefault("DRI_PRIME", "1")

  def apply_ntsync():
      # Kernel NT sync primitives: better frame pacing than fsync/futex in
      # CPU-heavy titles. FUNCTIONAL probe, not a file check: open the
      # device and actually create a semaphore via ioctl. Only a fully
      # working ntsync yields "1"; any failure (no device, no permission,
      # ABI mismatch, driver refusing) yields an explicit "0" so Proton
      # never selects a backend that will die at runtime.
      # User override (Steam LaunchOptions / launchparams.nix) wins.
      if "PROTON_USE_NTSYNC" in os.environ:
          return
      ok = False
      try:
          import fcntl, struct
          fd = os.open("/dev/ntsync", os.O_RDWR)
          try:
              # v6.14+ final ABI: NTSYNC_IOC_CREATE_SEM =
              # _IOW('N', 0x80, {u32 count, u32 max}) → returns sem fd.
              # Verified against the running kernel (7.1.8-zen1).
              try:
                  sem = fcntl.ioctl(
                      fd, 0x40084E80, bytearray(struct.pack("II", 0, 1)))
                  if isinstance(sem, int) and sem >= 0:
                      os.close(sem)
                      ok = True
              except OSError:
                  # pre-6.14 RFC ABI (e.g. 6.12 backports):
                  # _IOWR('N', 0x80, {u32 sem, u32 count, u32 max}),
                  # sem fd written into args.
                  buf = bytearray(struct.pack("III", 0, 0, 1))
                  fcntl.ioctl(fd, 0xC00C4E80, buf)
                  sem = struct.unpack("III", bytes(buf))[0]
                  os.close(sem)
                  ok = True
          finally:
              os.close(fd)
      except OSError:
          ok = False
      os.environ["PROTON_USE_NTSYNC"] = "1" if ok else "0"

  def gpu_vendor():
      # Games render on the dGPU (PRIME offload above), so loaded driver
      # decides the variant: proprietary Nvidia if present, else AMD if an
      # AMD card exists. Intel-only hosts get no per-vendor params.
      if os.path.exists("/proc/driver/nvidia/version"):
          return "nvidia"
      try:
          for card in os.listdir("/sys/class/drm"):
              if not card.startswith("card") or "-" in card:
                  continue
              with open(f"/sys/class/drm/{card}/device/vendor") as f:
                  if f.read().strip() == "0x1002":
                      return "amd"
      except OSError:
          pass
      return None

  def apply_launch_params(cmd):
      # Look up "<appid>_<vendor>". Leading KEY=VAL tokens become env vars;
      # the rest are appended after the game command, exactly like args in
      # Steam's own LaunchOptions field.
      appid = os.environ.get("SteamAppId") \
          or os.environ.get("STEAM_COMPAT_APP_ID")
      vendor = gpu_vendor()
      if not appid or not vendor:
          return cmd
      spec = LAUNCH_PARAMS.get(f"{appid}_{vendor}")
      if not spec:
          return cmd
      args = []
      for tok in shlex.split(spec):
          key, sep, val = tok.partition("=")
          if not args and sep and key.isidentifier():
              os.environ[key] = val
          else:
              args.append(tok)
      return cmd + args

  def main():
      apply_prime_offload()
      apply_ntsync()
      cmd = [GAMEMODERUN, *apply_launch_params(sys.argv[1:])]
      os.execvp(cmd[0], cmd)

  if __name__ == "__main__":
      main()
''
