{ ... }:

let
  opts = import ./options.nix;
  # systemMode = 2 → HTPC (Intel Arc only, no NVIDIA). Otherwise the dual
  # NVIDIA-PRIME + iGPU stack (desktop/laptop).
  gpuModule =
    if (opts.systemMode or 1) == 2
    then ./gpu/intel.nix
    else ./gpu/nvidia_intel.nix;
in
{
  imports = [
    ./boot.nix
    ../system/SDDM.nix
    ./networking.nix
    ./nix.nix
    ./nfs.nix
    ./ssh.nix
    ./gaming.nix
    ./packages.nix
    ./totalvim.nix
    ./users.nix
    ./timezone_locale.nix
    ./system_services.nix
    ./perf.nix
    ./wayland.nix
    ./sound.nix
    ./zram.nix
    ./security.nix
    gpuModule
    ./cpu/intel.nix
    ../system/nixlytile.nix
    ./newsboat.nix
    ./w3m.nix
    ./mpv.nix
    ./retroarch.nix
    ./drawingtablet.nix
    ../system/htpc.nix
    ../system/msi-ec.nix
    ../system/idle.nix
    ../services/nixly-ai
    ../services/on-demand
  ];
}
