{ python3, gamemode, writeScript, writeText, launchParams ? { } }:

# Per-game wrapper injected into every Steam app's LaunchOptions; applies PRIME
# offload, the per-GPU parameters from launchparams.nix, and gamemoderun.
# Its store path is baked into each entry, so autoconfig.nix re-patches on launch.
writeScript "nixly-game-wrap" ''
  #!${python3}/bin/python3
  """Wrap %command% with PRIME offload + per-GPU params + gamemoderun."""
  import json, os, shlex, sys

  GAMEMODERUN = "${gamemode}/bin/gamemoderun"

  # Kept in its own store file, since inlining JSON breaks on embedded quotes.
  with open("${writeText "nixly-launch-params.json"
      (builtins.toJSON launchParams)}") as _f:
      LAUNCH_PARAMS = json.load(_f)

  def apply_prime_offload():
      # Per-game only: forcing the Steam UI itself onto the dGPU crashes CEF in a
      # respawn loop, since /run/opengl-driver is unbound inside the runtime.
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
      # Functional ntsync probe, not a file check: only a semaphore that actually
      # gets created yields "1", so Proton never picks a backend that dies later.
      if "PROTON_USE_NTSYNC" in os.environ:
          return
      ok = False
      try:
          import fcntl, struct
          fd = os.open("/dev/ntsync", os.O_RDWR)
          try:
              # Final 6.14+ ABI: create-sem returns the semaphore fd.
              try:
                  sem = fcntl.ioctl(
                      fd, 0x40084E80, bytearray(struct.pack("II", 0, 1)))
                  if isinstance(sem, int) and sem >= 0:
                      os.close(sem)
                      ok = True
              except OSError:
                  # Pre-6.14 RFC ABI writes the semaphore fd into args instead.
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

  def apply_fps_cap():
      # Cap fps through MangoHud's Vulkan layer (no_display, so nothing is
      # drawn). VRR output: refresh-4 keeps frametimes inside the VRR window;
      # hitting the top of the range falls back to vsync pacing (judder).
      # Fixed-Hz output: cap at exactly refresh, which stops render-queue
      # buildup without fighting vsync. The focused monitor is where
      # nixlytile puts the game; a MANGOHUD/MANGOHUD_CONFIG set by the user
      # (Steam launch options or launchparams.nix) always wins.
      if "MANGOHUD" in os.environ or "MANGOHUD_CONFIG" in os.environ:
          return
      sock_path = os.environ.get("NIRI_SOCKET")
      if not sock_path:
          return
      import socket
      try:
          s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
          s.settimeout(1.0)
          s.connect(sock_path)
          s.sendall(b'"Outputs"\n')
          data = b""
          while not data.endswith(b"\n"):
              chunk = s.recv(65536)
              if not chunk:
                  break
              data += chunk
          s.close()
          outputs = list(json.loads(data)["Ok"]["Outputs"].values())
      except (OSError, ValueError, KeyError, TypeError):
          return

      def refresh_mhz(o):
          try:
              return o["modes"][o["current_mode"]]["refresh_rate"]
          except (KeyError, IndexError, TypeError):
              return 0

      pick = next((o for o in outputs if o.get("focused")), None)
      if pick is None or refresh_mhz(pick) <= 0:
          pick = max(outputs, key=refresh_mhz, default=None)
      if pick is None:
          return
      hz = refresh_mhz(pick) // 1000
      if hz < 30:
          return
      cap = hz - 4 if pick.get("vrr_supported") else hz
      os.environ["MANGOHUD"] = "1"
      os.environ["MANGOHUD_CONFIG"] = f"no_display,fps_limit={cap}"

  def gpu_vendor():
      # The loaded driver picks the variant; Intel-only hosts get no per-vendor params.
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
      # Leading KEY=VAL tokens become env vars; the rest are appended as args.
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
      # After apply_launch_params, so a per-game MANGOHUD_CONFIG wins.
      apply_fps_cap()
      os.execvp(cmd[0], cmd)

  if __name__ == "__main__":
      main()
''
