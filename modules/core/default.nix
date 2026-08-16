{ ... }:

{
  imports = [
    ./lockscreen.nix
    ./input.nix
    ./boot.nix
    ../system/SDDM.nix
    ./networking.nix
    ./tailscale.nix
    ./ssh_gate.nix
    ./autoupdate.nix
    ./nix.nix
    ./nfs.nix
    ./ssh.nix
    ./gaming.nix
    ./gametune.nix
    ./packages.nix
    ./totalvim.nix
    ./users.nix
    ./timezone_locale.nix
    ./system_services.nix
    ./docs.nix
    ./perf.nix
    ./prewarm.nix
    ./overhead.nix
    ./wayland.nix
    ./sound.nix
    ./zram.nix
    ./security.nix
    ./power.nix
    # scripts/detect-hw.sh skriver cpu/ og gpu/-imports rett under dette
    # ankeret foer hver eval (install, update, rebuild), ut fra faktisk
    # hardware, og fjerner de gamle linjene foerst. Derfor staar ingen av dem
    # committet her. msi-ec og nixos-hardware-modulene: se ./hw/profile.nix.
    # <detect-hw: cpu + gpu>
    ./cpu/intel.nix
    ./gpu/nvidia_intel.nix
    ./gpu/intel_igpu.nix
    ../system/nixlytile.nix
    ./newsboat.nix
    ./w3m.nix
    ./mpv.nix
    ./retroarch.nix
    ./drawingtablet.nix
    ./citrix.nix
    ./dcspit.nix
    ../system/htpc.nix
    ../system/idle.nix
    # GENERERT av scripts/detect-hw.sh: laptop/modell-spesifikke moduler fra
    # nixos-hardware (og msi-ec paa MSI-laptoper), og tjenester som bare skal
    # kjoere naar enheten finnes (bluetooth, fprintd, boltd).
    ./hw/profile.nix
    ./hw/devices.nix
    ../services/on-demand
  ];
}
