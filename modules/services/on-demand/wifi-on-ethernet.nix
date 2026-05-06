{ config, lib, pkgs, ... }:

{
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "wifi-toggle-on-ethernet" ''
        iface="$1"
        action="$2"

        case "$iface" in
          en*|eth*) ;;
          *) exit 0 ;;
        esac

        case "$action" in
          up)
            if ${pkgs.iproute2}/bin/ip -4 addr show dev "$iface" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
              ${pkgs.networkmanager}/bin/nmcli radio wifi off || true
            fi
            ;;
          down|pre-down)
            ${pkgs.networkmanager}/bin/nmcli radio wifi on || true
            ;;
        esac
      '';
    }
  ];
}
