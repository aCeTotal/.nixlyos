# GENERERT av scripts/detect-hw.sh — ikke rediger manuelt.
# DMI: vendor="System manufacturer" product="System Product Name" chassis=3
# Type: stasjonaer
{ inputs, lib, ... }:

let
  hw = inputs.nixos-hardware.nixosModules;

  # Modell-spesifikke kandidater i prioritert rekkefoelge (DMI + register).
  # Foerste som finnes i nixos-hardware vinner; resten ignoreres.
  candidates = [
    "system-manufacturer-system-product-name"
    "system-manufacturer-strix-z270e-gaming"
    "system-manufacturer-to-be-filled-by-o-e-m"
  ];

  generic = [
    "common-pc"
    "common-pc-ssd"
  ];

  model = lib.findFirst (n: builtins.hasAttr n hw) null candidates;
  generic' = builtins.filter (n: builtins.hasAttr n hw) generic;
  missing = builtins.filter (n: !(builtins.hasAttr n hw)) generic;
in
lib.warnIf (missing != [ ])
  "hw/profile.nix: ukjente nixos-hardware-moduler: ${toString missing}"
{
  imports =
    map (n: hw.${n}) generic'
    ++ lib.optional (model != null) hw.${model};
}
