{ config, ... }:

{
  # Navnet i /etc/os-release (NAME/PRETTY_NAME), /etc/lsb-release,
  # boot-oppfoeringene og `nixos-version`.
  #
  # distroId beholdes som "nixos": ID-en er det verktoey (distrobox,
  # vscode-server, appimage-wrappere) sjekker for aa kjenne igjen plattformen,
  # og en egen ID gjoer at de faller tilbake til generisk Linux.
  system.nixos = {
    distroName = "NixlyOS";
    vendorName = "NixlyOS";

    # Feltene under haardkoder nixos.org/nixpkgs i version.nix — de er rene
    # strenger uten funksjon, saa de pekes hit i stedet. LOGO staar igjen paa
    # nix-snowflake: ikonet maa finnes i temaet for aa vises.
    extraOSReleaseArgs = {
      CPE_NAME = "cpe:/o:nixlyos:nixlyos:${config.system.nixos.release}";
      DEFAULT_HOSTNAME = "nixlyos";
      HOME_URL = "https://github.com/aCeTotal/.nixlyos";
      VENDOR_URL = "https://github.com/aCeTotal/.nixlyos";
      DOCUMENTATION_URL = "https://github.com/aCeTotal/.nixlyos";
      SUPPORT_URL = "https://github.com/aCeTotal/.nixlyos";
      BUG_REPORT_URL = "https://github.com/aCeTotal/.nixlyos/issues";
    };
  };
}
