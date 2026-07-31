{ pkgs, inputs, system, ... }:

let
  herdr = inputs.herdr.packages.${system}.default;
  jq = "${pkgs.jq}/bin/jq";

  # Terminal-shell for Alacritty: attacher til herdr. Hver prosjekt-rot
  # (git-rot av terminalens startmappe) faar sin egen workspace. Samme
  # rot -> gjenbruk, ingen duplikater. Kjoeres ikke over ssh — ssh faar
  # vanlig bash.
  herdr-shell = pkgs.writeShellScriptBin "herdr-shell" ''
    root=$(${pkgs.git}/bin/git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
    label=$(basename "$root")
    (
      # Workspace-kall feiler til klienten er attachet med ekte geometri
      # — derfor retry med backoff i stedet for aa polle server-status.
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
    ) &
    exec ${herdr}/bin/herdr
  '';

  # Super+Return / launcher: kjoerer allerede en herdr-klient -> hopp til
  # nixlytile-workspacen der herdr-vinduet staar (FocusWindow via
  # Niri-IPC) og lag ny tab i fokusert herdr-workspace. Ellers -> nytt
  # alacritty-vindu (som attacher via herdr-shell). Vinduet faar app-id
  # "nixly-herdr" saa FocusWindow ikke treffer vanlige alacritty-vinduer.
  herdr-launch = pkgs.writeShellScriptBin "herdr-launch" ''
    if ${pkgs.procps}/bin/pgrep -f 'bin/herdr$' >/dev/null; then
      if [ -n "$NIRI_SOCKET" ]; then
        printf '{"Action":{"FocusWindow":{"app_id":"nixly-herdr"}}}\n' \
          | ${pkgs.socat}/bin/socat -t 0.3 - UNIX-CONNECT:"$NIRI_SOCKET" >/dev/null 2>&1
      fi
      ws=$(${herdr}/bin/herdr api snapshot 2>/dev/null \
        | ${jq} -r '.result.snapshot.focused_workspace_id // empty')
      exec ${herdr}/bin/herdr tab create ''${ws:+--workspace "$ws"} --focus >/dev/null 2>&1
    fi
    exec alacritty --class nixly-herdr
  '';
in
{
  home.packages = [
    herdr
    herdr-shell
    herdr-launch
  ];

  # Launcher-oppfoeringen for Alacritty skal ogsaa gaa via herdr-launch,
  # slik at launcher og Super+Return oppfoerer seg likt.
  xdg.desktopEntries.Alacritty = {
    name = "Alacritty";
    genericName = "Terminal";
    exec = "herdr-launch";
    icon = "Alacritty";
    terminal = false;
    categories = [ "System" "TerminalEmulator" ];
  };

  xdg.configFile."herdr/config.toml".text = ''
    [terminal]
    # Nye paner/tabs arver cwd fra aktiv pane
    new_cwd = "follow"

    [ui]
    # ctrl+t skal lage tab med en gang — ikke aapne navnedialog
    # (dialogen sluker ogsaa paafoelgende cycle-taster til Enter/Esc).
    prompt_new_tab_name = false

    [keys]
    new_tab = "ctrl+t"
    previous_tab = "ctrl+left"
    next_tab = "ctrl+right"
    previous_workspace = "ctrl+up"
    next_workspace = "ctrl+down"
    previous_agent = "alt+up"
    next_agent = "alt+down"
    close_workspace = "ctrl+q"
    close_tab = "alt+q"
    new_workspace = "prefix+n"
  '';
}
