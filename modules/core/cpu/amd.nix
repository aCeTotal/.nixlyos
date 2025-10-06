{ config, lib, pkgs, ... }:

{
  hardware.cpu.amd.updateMicrocode = true;

  boot = {
    kernelModules = [ "kvm-amd" ];
    kernelParams = (lib.mkBefore [
      "amd_pstate=active"
    ]) ++ (lib.optionals (config.virtualisation.libvirtd.enable or false) [
      "amd_iommu=on" "iommu=pt"
    ]);
  };
  environment.systemPackages = with pkgs; [
    lm_sensors
    cpufrequtils
  ];
  services.power-profiles-daemon.enable = true;
}
