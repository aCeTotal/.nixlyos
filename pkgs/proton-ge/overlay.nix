final: prev:
let
  pin = builtins.fromJSON (builtins.readFile ./pin.json);
in {
  proton-ge-bin = prev.proton-ge-bin.overrideAttrs (_: {
    version = pin.version;
    src = prev.fetchurl {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${pin.version}/${pin.version}.tar.gz";
      hash = pin.hash;
    };
  });
}
