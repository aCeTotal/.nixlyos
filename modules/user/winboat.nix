{ config, lib, pkgs, nixpkgs-unstable ? null, system ? null, ... }:

let
  unstable = if nixpkgs-unstable != null && system != null
             then nixpkgs-unstable.legacyPackages.${system}
             else null;
  freerdpPkg = unstable.freerdp3;
in {
  assertions = [
    {
      assertion = unstable != null && unstable ? freerdp3;
      message = ''WinBoat requires freerdp3 from nixpkgs-unstable. Ensure nixpkgs-unstable is passed in extraSpecialArgs.'';
    }
  ];
  # Home Manager: install WinBoat and required client tools
  home.packages = [
    pkgs.winboat        # from aCeTotal/nixlypkgs overlay
    freerdpPkg          # strictly freerdp3 from unstable
    pkgs.docker-compose # Compose v2 CLI (also provides docker-compose command)
  ];

  # HM-level note
  warnings = [
    ''WinBoat: after enabling Docker system module, log out/in (or reboot) so docker group membership takes effect.''
  ];
}
