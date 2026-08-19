{ inputs, lib, ... }:

let
  hw = inputs.nixos-hardware.nixosModules;

  candidates = [
    "msi-gs66-stealth-10ug"
    "msi-ms-16v3"
    "msi-gs"
  ];

  generic = [
    "common-pc-laptop"
    "common-pc-laptop-ssd"
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
    ++ lib.optional (model != null) hw.${model}
    ++ [ ../../system/msi-ec.nix ];

  services.tlp.enable = lib.mkForce false;
}
