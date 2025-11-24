{ config, lib, pkgs, pkgs-unstable ? null, ... }:

let
  freerdpPkg = if pkgs-unstable != null then pkgs-unstable.freerdp3 else null;
in {
  assertions = [
    {
      assertion = pkgs-unstable != null && pkgs-unstable ? freerdp3;
      message = ''WinBoat requires freerdp3 from the unstable package set. Ensure pkgs-unstable is passed in extraSpecialArgs.'';
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
