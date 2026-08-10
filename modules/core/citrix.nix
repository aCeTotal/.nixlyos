{ lib, pkgs, ... }:

{
  # nixpkgs-modulen legger nixpkgs.overlays oppaa vaart pkgs-sett, og
  # nixlypkgs-modulen setter sitt eget overlay der. Uten mkAfter blir
  # wfica-wrapperen under overskrevet av den uwrappede pakka.
  nixpkgs.overlays = lib.mkAfter [ (import ../../pkgs/citrix/overlay.nix) ];

  environment.systemPackages = with pkgs; [
    citrix-workspace-nixly
  ];

  # Uten denne daemonen skriver wfica ingen logger i det hele tatt
  # (~/.ICAClient/logs/ICAClient.log blir aldri opprettet).
  systemd.user.services.ctxcwalogd = {
    description = "Citrix Workspace log daemon";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.citrix-workspace-nixly}/opt/citrix-icaclient/util/ctxcwalogd";
      Restart = "on-failure";
    };
  };

  # .ica-filer (application/x-ica) aapnes automatisk med wfica.
  xdg.mime = {
    enable = true;
    addedAssociations."application/x-ica" = "wfica.desktop";
    defaultApplications."application/x-ica" = "wfica.desktop";
  };

  # wfclient.ini eies av Citrix (wfica skriver den ved GUI-endringer), saa den
  # kan ikke symlinkes fra store. Vi patcher bare noeklene vi trenger.
  home-manager.users.total = { lib, ... }: {
    home.activation.citrixWfclientIni = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      INI="$HOME/.ICAClient/wfclient.ini"
      if [ -f "$INI" ]; then
        # UseFullScreen=True (Citrix-default i wfclient.template) lager et
        # vindu paa hele X-skjermen - 5360x1440 over begge monitorer - saa
        # sesjonen starter "fullskjerm" med svart bakgrunn og innholdet paa
        # DP-1-delen. nixlytile flislegger den foerst ved neste layout-event.
        ${pkgs.gnused}/bin/sed -i \
          's/^UseFullScreen[[:space:]]*=.*/UseFullScreen=False/' "$INI"

        # A: i sesjonen mappes til hjemmemappa, ikke rota. $HOME ekspanderes
        # av wfica selv (samme som PersistentCachePath i templaten).
        ${pkgs.gnused}/bin/sed -i \
          's|^DrivePathA[[:space:]]*=.*|DrivePathA=$HOME|' "$INI"

        # SuperMetaToWinKeys=True (module.ini-default) sender lokal Super inn
        # i sesjonen som Win-tast -> Windows startmeny popper opp hver gang.
        # wfclient.ini vinner over module.ini.
        if ${pkgs.gnugrep}/bin/grep -q '^SuperMetaToWinKeys' "$INI"; then
          ${pkgs.gnused}/bin/sed -i \
            's/^SuperMetaToWinKeys[[:space:]]*=.*/SuperMetaToWinKeys=False/' "$INI"
        else
          ${pkgs.gnused}/bin/sed -i \
            '/^\[WFClient\]/a SuperMetaToWinKeys=False' "$INI"
        fi
      fi
    '';
  };

  # Chrome lagrer "aapne alltid denne filtypen" i profilen (extensions_to_open),
  # og den forsvinner naar profilen resettes. Enterprise-policy gjoer det
  # permanent: nedlastede .ica-filer aapnes rett i wfica.
  environment.etc."opt/chrome/policies/managed/citrix-ica.json".text =
    builtins.toJSON { AutoOpenFileTypes = [ "ica" ]; };
}
