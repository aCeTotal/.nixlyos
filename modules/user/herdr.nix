{ pkgs, inputs, system, ... }:

let
  herdr = inputs.herdr.packages.${system}.default;
  jq = "${pkgs.jq}/bin/jq";

  # Terminal-shell for Alacritty: attacher til herdr. Hver prosjekt-rot
  # (git-rot av terminalens startmappe) faar sin egen workspace med en
  # "Claude"-tab ved siden av terminalen. Samme rot -> gjenbruk, ingen
  # duplikater. Kjoeres ikke over ssh — ssh faar vanlig bash.
  herdr-shell = pkgs.writeShellScriptBin "herdr-shell" ''
    root=$(${pkgs.git}/bin/git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
    label=$(basename "$root")
    (
      # Pane-spawn feiler med "ghostty error -2" (rows=0 cols=0) helt til
      # klienten er attachet med ekte geometri — derfor retry med backoff
      # paa alt som lager paner, i stedet for aa polle server-status.
      ws=""
      for _ in $(seq 40); do
        ws=$(${herdr}/bin/herdr workspace list 2>/dev/null \
          | ${jq} -r --arg l "$label" '[.result.workspaces[] | select(.label == $l)][0].workspace_id // empty' 2>/dev/null)
        if [ -n "$ws" ]; then
          ${herdr}/bin/herdr workspace focus "$ws" >/dev/null 2>&1
          break
        fi
        ws=$(${herdr}/bin/herdr workspace create --cwd "$root" --label "$label" --focus 2>/dev/null \
          | ${jq} -r '.result.workspace.workspace_id // empty' 2>/dev/null)
        [ -n "$ws" ] && break
        sleep 0.5
      done
      [ -z "$ws" ] && exit 0
      if ! ${herdr}/bin/herdr tab list --workspace "$ws" 2>/dev/null \
          | ${jq} -e '.result.tabs[] | select(.label == "Claude")' >/dev/null 2>&1; then
        pane=""
        for _ in $(seq 20); do
          pane=$(${herdr}/bin/herdr tab create --workspace "$ws" --cwd "$root" --label Claude --no-focus 2>/dev/null \
            | ${jq} -r '.result.root_pane.pane_id // empty' 2>/dev/null)
          [ -n "$pane" ] && break
          sleep 0.5
        done
        # Agentnavn maa vaere unikt server-wide -> claude-<workspace-id>
        [ -n "$pane" ] && ${herdr}/bin/herdr agent start "claude-$ws" --kind claude --pane "$pane" \
          -- --dangerously-skip-permissions >/dev/null 2>&1
      fi
    ) &
    exec ${herdr}/bin/herdr
  '';
in
{
  home.packages = [
    herdr
    herdr-shell
  ];

  xdg.configFile."herdr/config.toml".text = ''
    [terminal]
    # Nye paner/tabs arver cwd fra aktiv pane
    new_cwd = "follow"

    [keys]
    new_tab = "ctrl+t"
    previous_tab = "ctrl+left"
    next_tab = "ctrl+right"
    new_workspace = "prefix+n"

    # Claude popup i aktiv panes mappe: Alt+C (direkte) eller Ctrl+B C.
    # Ctrl+C gaar ikke — det er SIGINT (avbryt prosess) i alle terminaler.
    # Popup lever til claude avsluttes (engangsbruk); persistent claude
    # ligger i "Claude"-taben som herdr-shell lager automatisk.
    [[keys.command]]
    key = "alt+c"
    type = "popup"
    command = "claude --dangerously-skip-permissions"
    description = "Claude Code"
    width = "90%"
    height = "90%"

    [[keys.command]]
    key = "prefix+c"
    type = "popup"
    command = "claude --dangerously-skip-permissions"
    description = "Claude Code"
    width = "90%"
    height = "90%"
  '';
}
