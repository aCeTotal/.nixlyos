{ python3, gamemode, writeScript }:

# Per-game wrapper injected into every Steam app's LaunchOptions as
# `<this> %command%`. Applies PRIME offload (hybrid-GPU) and chains
# gamemoderun in front of the actual game binary.
#
# Steam stores LaunchOptions as plain text, so the absolute store path is
# baked into every per-app entry; autoconfig.nix re-patches on each launch so
# a new build's path replaces the old one before any game runs.
writeScript "nixly-game-wrap" ''
  #!${python3}/bin/python3
  """Wrap %command% with PRIME offload + gamemoderun."""
  import os, sys

  GAMEMODERUN = "${gamemode}/bin/gamemoderun"

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

  def main():
      apply_prime_offload()
      cmd = [GAMEMODERUN, *sys.argv[1:]]
      os.execvp(cmd[0], cmd)

  if __name__ == "__main__":
      main()
''
