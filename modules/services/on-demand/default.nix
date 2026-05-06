{ ... }:

{
  imports = [
    ./tablet.nix
    ./wifi-on-ethernet.nix
    ./ollama.nix
    ./strongswan.nix
    ./chrome.nix
  ];
}
