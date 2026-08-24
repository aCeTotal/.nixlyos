# Latest prebuilt Proton-CachyOS via chaotic-nyx (a plain fetch of the official
# CachyOS release tarball, never built from source). x86-64-v3 build when the
# CPU supports it, generic x86_64 otherwise.
{ inputs, system }:
let
  chaotic = inputs.chaotic.unrestrictedPackages.${system};
in
if (import ../hw/resources.nix).cpuLevel >= 3
then chaotic.proton-cachyos_x86_64_v3
else chaotic.proton-cachyos
