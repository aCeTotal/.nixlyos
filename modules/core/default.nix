{ ... }:

{
  imports = [
    ./boot.nix
    ./ly.nix
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
    ./wayland.nix
    ./sound.nix
    ./zram.nix
    ./security.nix
    ./gpu/nvidia_intel.nix
    ./cpu/intel.nix
    ../system/msi-ec.nix
    ./nixlytile.nix
    ./emulators.nix
    ./newsboat.nix
    ./drawingtablet.nix
    #./kde.nix
  ];
}
