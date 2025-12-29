{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu_kvm
    virt-manager
    virt-viewer
    spice-gtk
    looking-glass-client
    swtpm
  ];

  boot.kernelModules = [
    "kvm" "kvm-intel" "kvm-amd"
    "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"
  ];

  boot.kernelParams = [
    "intel_iommu=on"
    "amd_iommu=on"
    "iommu=pt"
  ];

  boot.extraModprobeConfig = ''
    options kvm-intel nested=1
    options kvm-amd nested=1
  '';

  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      onShutdown = "shutdown";
      shutdownTimeout = 60;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        runAsRoot = true;
      };
    };
  };
}
