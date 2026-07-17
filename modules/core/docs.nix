{ ... }:

{
  # NixOS-manualen bygges ellers på hver rebuild — eval-tid, build-IO og
  # disk for noe som leses på nixos.org uansett. Man-pages beholdes.
  documentation.nixos.enable = false;
}
