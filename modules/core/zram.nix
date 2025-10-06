{ config, lib, pkgs, ... }:

{
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "lz4";
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_bytes" = 268435456;
    "vm.dirty_bytes" = 1073741824;
    "vm.min_free_kbytes" = 65536;
  };

  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
  };
}
