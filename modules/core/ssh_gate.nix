{ pkgs, ... }:

{
  # SSH-gate: LAN-ssh aapen til tailscale er logget inn, deretter helt
  # stengt. Baseline i brannmuren er stengt (openssh.openFirewall =
  # false i ssh.nix); gaten legger inn/fjerner en runtime-regel i
  # nixos-fw/input-allow basert paa tailscale BackendState.
  #
  # Failsafe: logges tailscale ut (eller `tailscale down`) aapner
  # LAN-ssh igjen innen ~10s — du laases aldri ute av egen boks.
  # Brannmur-reload (rebuild) nullstiller regelen; loopen reetablerer.
  systemd.services.ssh-tailscale-gate = {
    description = "Open LAN ssh until tailscale is logged in";
    wantedBy = [ "multi-user.target" ];
    after = [ "firewall.service" "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    path = [ pkgs.nftables pkgs.tailscale pkgs.jq pkgs.gawk pkgs.gnugrep ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      while true; do
        state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "unknown"' || true)
        rules=$(nft -a list chain inet nixos-fw input-allow 2>/dev/null || true)
        handles=$(printf '%s\n' "$rules" | awk '/tcp dport 22 accept/ {print $NF}')
        if [ "$state" = "Running" ]; then
          for h in $handles; do
            nft delete rule inet nixos-fw input-allow handle "$h" 2>/dev/null || true
          done
        else
          if [ -z "$handles" ]; then
            nft add rule inet nixos-fw input-allow tcp dport 22 accept 2>/dev/null || true
          fi
        fi
        sleep 10
      done
    '';
  };
}
