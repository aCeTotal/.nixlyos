{ lib, pkgs, ... }:

{
  services.cachefilesd.enable = true;
  # NFS client option was removed in newer NixOS; mounts work without it.

  # Ensure mount directories exist at boot
  systemd.tmpfiles.rules = [
    "d /mnt/nfs 0755 root root -"
    "d /mnt/nfs/Bigdisk1 0755 root root -"
  ];

  fileSystems."/mnt/nfs/Bigdisk1" = {
    device = "192.168.0.40:/bigdisk1";
    fsType = "nfs";
    options = [
      "rw"
      "x-systemd.automount"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.idle-timeout=2min"
      "x-systemd.mount-timeout=2s"
      "x-systemd.device-timeout=2s"
      "vers=4.2"
      "rsize=1048576"
      "wsize=1048576"
      "nconnect=8"
      # Prefer fast failure on access if server is down
      "soft"
      "timeo=5"
      "retrans=2"
      "fsc"
      "acl"
      "noatime"
      "nodiratime"
      "tcp"
      "lookupcache=positive"
    ];
  };
}
