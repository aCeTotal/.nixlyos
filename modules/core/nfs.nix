{ lib, pkgs, ... }:

{
  services.cachefilesd = {
    enable = true;
    # Tillat cache å bruke mer plass før cleanup starter
    # brun = start cleanup, bcull = aggressiv cleanup, bstop = stopp caching
    extraConfig = ''
      brun 20%
      bcull 10%
      bstop 5%
      frun 20%
      fcull 10%
      fstop 5%
    '';
  };

  # Ensure mount directories exist at boot
  systemd.tmpfiles.rules = [
    "d /mnt/nfs 0755 root root -"
    "d /mnt/nfs/Bigdisk1 0755 root root -"
  ];

  fileSystems."/mnt/nfs/Bigdisk1" = {
    device = "10.0.0.8:/bigdisk1";
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
      "soft"
      "timeo=5"
      "retrans=2"
      "fsc"
      "acl"
      "noatime"
      "nodiratime"
      "tcp"
      "lookupcache=all"
      "actimeo=300"
      "nocto"
    ];
  };
}
