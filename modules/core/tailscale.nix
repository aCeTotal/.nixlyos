{ pkgs, ... }:

{
  # Foerstegangsaktivering: `tailscale-init` — logger inn (viser link),
  # venter til tilkoblet og bekrefter at ssh kun naas via tailnettet.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "tailscale-init" ''
      set -e
      sudo tailscale up --ssh
      until [ "$(tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r .BackendState)" = "Running" ]; do
        sleep 1
      done
      ip=$(tailscale ip -4 2>/dev/null | head -1)
      echo ""
      echo "Tailscale aktiv ($ip). Venter paa at LAN-ssh stenges..."
      for _ in $(seq 30); do
        sudo ${pkgs.nftables}/bin/nft list chain inet nixos-fw input-allow 2>/dev/null \
          | grep -q 'tcp dport 22 accept' || break
        sleep 1
      done
      echo "SSH stengt for LAN/internett — naas naa kun via tailnettet:"
      echo "  ssh total@$(hostname)   # fra enhver tailnet-enhet, uten noekkel/passord"
      echo "Aktive ssh-oekter overlever; nye maa gaa via tailscale."
    '')
  ];

  services.tailscale = {
    enable = true;
    # Tailscale SSH: tailnet-identitet er innloggingen, ingen noekler/passord.
    # NB: extraUpFlags brukes kun ved auto-up (authKeyFile); ved manuell
    # foerste innlogging maa flagget med: sudo tailscale up --ssh
    extraUpFlags = [ "--ssh" ];
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
