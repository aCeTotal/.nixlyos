{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./nix.nix
    ./virt.nix
    ./nfs.nix
    ./ssh.nix
    ./gaming.nix
    ./packages.nix
    ./neovim/default.nix
    ./users.nix
    ./timezone_locale.nix
    ./wayland.nix
    ./sound.nix
    ./zram.nix
    ./gpu/nvidia.nix
    ./cpu/intel.nix
  ];
}
