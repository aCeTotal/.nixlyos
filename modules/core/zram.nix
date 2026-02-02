{ config, lib, pkgs, ... }:

{
  zramSwap = {
    enable = true;
    memoryPercent = 100;          # Use up to 100% of RAM as compressed swap
    algorithm = "zstd";           # Better compression ratio than lz4
    priority = 100;               # Higher priority than disk swap
  };

  boot.kernel.sysctl = {
    # Swap behavior tuned for zram
    "vm.swappiness" = 180;        # Higher for zram (kernel 5.8+)
    "vm.page-cluster" = 0;        # Disable readahead for zram (random access is fast)
    "vm.vfs_cache_pressure" = 50; # Keep dentries/inodes in cache longer

    # Writeback tuning for responsiveness
    "vm.dirty_background_ratio" = 5;     # Start background writeback at 5% dirty
    "vm.dirty_ratio" = 15;               # Throttle writes at 15% dirty
    "vm.dirty_expire_centisecs" = 3000;  # Expire dirty pages after 30s
    "vm.dirty_writeback_centisecs" = 1500; # Writeback interval 15s

    # Memory overcommit for gaming
    "vm.overcommit_memory" = 1;   # Always allow overcommit (games often over-allocate)
    "vm.min_free_kbytes" = 131072; # Keep 128MB free minimum
  };

  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableRootSlice = true;
    enableSystemSlice = true;
  };
}
