#!/usr/bin/env bash
# Live build view for update.sh: reads the nix output on stdin, shows what nix is
# working on right now and lists every package that changes version.
set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

tty=0; [ -t 2 ] && tty=1
frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
frame=0 started=0
# nixos-rebuild evaluates before it prints anything, which is the longest silent
# stretch of the run, so the view starts out naming that phase.
current="evaluating configuration" tag=""
builds=0 fetches=0 build_total=0 fetch_total=0

declare -A old_ver seen

# Name and version of everything in the running system, so a package can be shown
# as old → new the moment nix starts on it.
while read -r p; do
  nv=${p##*/}; nv=${nv#*-}
  [[ $nv =~ ^(.+)-([0-9][a-zA-Z0-9._+]*)(-(dev|man|doc|lib|bin|out|info|debug))?$ ]] || continue
  old_ver[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
done < <(nix-store -q --requisites /run/current-system 2>/dev/null || true)

# The spinner line is redrawn in place; upgrades scroll above it.
spin() {
  (( tty )) || return 0
  local el=$(( SECONDS - started ))
  printf '\r\e[2K    %s%s%s %s%s%s%.60s  %s%dm%02ds%s' \
    "$_ui_c" "${frames[frame]}" "$_ui_0" \
    "$_ui_d" "$tag" "$_ui_0" "$current" \
    "$_ui_d" $((el / 60)) $((el % 60)) "$_ui_0" >&2
  frame=$(( (frame + 1) % ${#frames[@]} ))
}

upgraded() { # name old new
  (( tty )) && printf '\r\e[2K' >&2
  printf '    %s%-28s%s %s %s→%s %s%s%s\n' \
    "$_ui_b" "$1" "$_ui_0" "$2" "$_ui_d" "$_ui_0" "$_ui_g" "$3" "$_ui_0" >&2
}

phase() { # text
  current=$1
  tag=""
  started=$SECONDS
}

note() { # act store-basename
  local nv=${2#*-}
  local n tot
  if [ "$1" = building ]; then
    builds=$((builds + 1)); n=$builds tot=$build_total
  else
    fetches=$((fetches + 1)); n=$fetches tot=$fetch_total
  fi
  (( tot )) && tag="[$n/$tot] " || tag="[$n] "
  started=$SECONDS
  current="$1 $nv"
  [[ $nv =~ ^(.+)-([0-9][a-zA-Z0-9._+]*)(-(dev|man|doc|lib|bin|out|info|debug))?$ ]] || return 0
  local name=${BASH_REMATCH[1]} ver=${BASH_REMATCH[2]} old=${old_ver[${BASH_REMATCH[1]}]-}
  [ -n "$old" ] && [ "$old" != "$ver" ] && [ -z "${seen[$name]-}" ] || return 0
  seen[$name]=1
  upgraded "$name" "$old" "$ver"
}

started=$SECONDS   # the closure scan above must not count as build time
while :; do
  if IFS= read -r -t 0.2 line; then
    case $line in
      *"building '/nix/store/"*.drv"'"*)
        p=${line#*/nix/store/}; note building "${p%%.drv\'*}";;
      *"copying path '/nix/store/"*)
        p=${line#*/nix/store/}; note downloading "${p%%\'*}";;
      # The counts nix prints up front turn the spinner into n-of-total progress.
      "these "*" derivations will be built"*|"this derivation will be built"*)
        [[ $line =~ these\ ([0-9]+)\ derivations ]] && build_total=${BASH_REMATCH[1]} || build_total=1;;
      "these "*" paths will be fetched"*|"this path will be fetched"*)
        [[ $line =~ these\ ([0-9]+)\ paths ]] && fetch_total=${BASH_REMATCH[1]} || fetch_total=1;;
      "building the system configuration"*) phase "evaluating configuration";;
      "Checking switch inhibitors"*)        phase "checking switch inhibitors";;
      "activating the configuration"*)      phase "activating configuration";;
      "setting up /etc"*)                   phase "setting up /etc";;
      "reloading user units"*|"restarting"*|"reloading"*|"starting"*|"stopping"*)
        phase "${line%%...}";;
      "Done. The new configuration is"*)    phase "done";;
    esac
  elif (( $? <= 128 )); then
    break
  fi
  spin
done

# The spinner line is scratch space; the summary printed after it must start clean.
(( tty )) && printf '\r\e[2K' >&2
exit 0
