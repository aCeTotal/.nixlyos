{ ... }:

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
    ./gpu/nvidia_intel.nix
    ./cpu/intel.nix
    ../system/niri.nix
    ./newsboat.nix
    ./w3m.nix
    ./mpv.nix
    ./retroarch.nix
    ./drawingtablet.nix
    ../system/htpc.nix
    ../system/msi-ec.nix
    ../system/idle.nix
    ../services/nixly-ai
  ];
}
