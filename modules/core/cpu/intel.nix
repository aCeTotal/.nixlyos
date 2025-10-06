{ config, lib, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    kernelModules = [ "kvm-intel" ];
    # Wrap the entire list with mkBefore; the option expects a list.
    kernelParams = lib.mkBefore ([
      "intel_pstate=active"
    ] ++ (lib.optionals (config.virtualisation.libvirtd.enable or false) [
      "intel_iommu=on" "iommu=pt"
    ]));
  };

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  environment.systemPackages = with pkgs; [
    lm_sensors
    cpufrequtils
  ];
}
