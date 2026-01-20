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
    ./neovim/default.nix
    ./users.nix
    ./timezone_locale.nix
    ./system_services.nix
    ./wayland.nix
    ./sound.nix
    ./zram.nix
    ./gpu/nvidia.nix
    ./cpu/intel.nix
  ];
}
