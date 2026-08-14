{ ... }:

{
  # dcspitd: web-surfacer til nettbrett/telefon + mDNS-navnet dcspit.local.

  # Web-surfacene (dcspitd cfg.port, default 8080) og mDNS-responderen
  # (libmdns i dcspitd, UDP 5353) maa slippe inn — ellers ser hverken
  # nettbrettet siden eller mDNS-spoerringene responderen.
  networking.firewall.allowedTCPPorts = [ 8080 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  # systemd-resolved svarer ikke paa mDNS-navn som en annen responder paa
  # SAMME maskin annonserer (den ignorerer mDNS-pakker fra egne adresser).
  # Derfor slaar dcspit.local opp fint fra nettbrettet, men ikke lokalt.
  # /etc/hosts leses foer alle scopes, saa denne linja fikser lokalt oppslag.
  networking.hosts."127.0.0.1" = [ "dcspit.local" ];
}
