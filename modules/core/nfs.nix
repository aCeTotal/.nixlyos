{ lib, pkgs, ... }:

{
  # NFS-støtte (nfs-utils, rpcbind, kernel-moduler)
  boot.supportedFilesystems = [ "nfs" ];

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

  # Rask tilgjengelighetsjekk - feiler umiddelbart (~1s) når NFS-server er utilgjengelig.
  # Mount-enheten avhenger av denne, så mount prøver aldri å koble til en
  # utilgjengelig server (som ville blokkert Thunar i minutter pga TCP SYN-timeout).
  systemd.services.nfs-bigdisk1-check = {
    description = "Check NFS server 10.0.0.8 reachability";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.iputils}/bin/ping -c 1 -W 1 10.0.0.8 > /dev/null 2>&1'";
    };
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
  };

  # NFS mount-enhet med avhengighet til tilgjengelighetssjekken.
  # Flyten: aksess → automount trigger → mount krever ping-sjekk →
  #   Server nede: ping feiler (~1s) → mount feiler → Thunar fortsetter
  #   Server oppe: ping OK → mount kjører normalt
  systemd.mounts = [{
    what = "10.0.0.8:/bigdisk1";
    where = "/mnt/nfs/Bigdisk1";
    type = "nfs";
    mountConfig = {
      Options = lib.concatStringsSep "," [
        "rw"
        "vers=4.2"
        "rsize=1048576"
        "wsize=1048576"
        "nconnect=8"
        "soft"
        "timeo=5"
        "retrans=2"
        "retry=0"
        "fsc"
        "acl"
        "noatime"
        "nodiratime"
        "tcp"
        "lookupcache=all"
        "actimeo=300"
        "nocto"
      ];
      TimeoutSec = "5s";
    };
    requires = [ "nfs-bigdisk1-check.service" ];
    after = [ "nfs-bigdisk1-check.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
  }];

  # Automount - trigger mount ved aksess til /mnt/nfs/Bigdisk1
  systemd.automounts = [{
    where = "/mnt/nfs/Bigdisk1";
    automountConfig = {
      TimeoutIdleSec = "2min";
    };
    wantedBy = [ "multi-user.target" ];
  }];
}
