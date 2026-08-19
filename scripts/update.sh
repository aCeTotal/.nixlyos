#!/usr/bin/env bash
# Full update: bump the stable branch if a new NixOS release exists, bump the
# proton-ge pin, update every flake input and build for the next boot.
set -euo pipefail

REPO="$HOME/.nixlyos"
FLAKE="$REPO/flake.nix"
. "$REPO/scripts/ui.sh"

# The tree is always dirty because detect-hw.sh writes generated files, and the
# setting in nix.nix only applies after the next activation.
export NIX_CONFIG="warn-dirty = false"

# Ask for the password first, then keep the sudo timestamp warm so the final
# rebuild does not hit the five-minute timeout.
ui_head "NixlyOS update"
sudo -v
# Own session and closed streams: killing the group takes the running sleep with
# it, and it never holds the script's stdout open after the exit.
setsid bash -c 'while sudo -n true; do sleep 50; done' </dev/null >/dev/null 2>&1 &
sudo_keepalive=$!
trap 'kill -- -"$sudo_keepalive" 2>/dev/null' EXIT

STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/nixlyos/last-build"
mkdir -p "$(dirname "$STAMP")"

# Flake eval only sees tracked files, so their contents plus the running system
# identify the last known result. 14 ms, against 11 s for the eval it replaces.
# cd, because ls-files prints paths relative to the repo, not to the caller's cwd.
tree_key() { (cd "$REPO" && git ls-files -z | xargs -0 sha1sum) | sha1sum | cut -d' ' -f1; }

ui_head "Hardware"
# The cpu/gpu imports must match the machine before eval.
bash "$REPO/scripts/detect-hw.sh" "$REPO"

cur=$(grep -oP 'nixpkgs/nixos-\K[0-9]{2}\.[0-9]{2}' "$FLAKE")

# 25.11 -> 26.05 -> 26.11 -> 27.05 ...
next_ver() {
  local y=${1%%.*} m=${1##*.}
  if [ "$m" = "05" ]; then echo "$y.11"; else printf '%02d.05\n' $((10#$y + 1)); fi
}

has_branch() { git ls-remote --exit-code --heads "$1" "$2" >/dev/null 2>&1; }

# Only jump releases when both branches exist; home-manager against the wrong
# nixpkgs base breaks eval.
new=$cur
while cand=$(next_ver "$new") &&
      has_branch https://github.com/NixOS/nixpkgs "nixos-$cand" &&
      has_branch https://github.com/nix-community/home-manager "release-$cand"; do
  new=$cand
done

ui_head "Channel"
if [ "$new" != "$cur" ]; then
  ui_ok "Bumped channel from $cur to the newest: $new"
  sed -i "s|nixpkgs/nixos-$cur|nixpkgs/nixos-$new|; s|home-manager/release-$cur|home-manager/release-$new|" "$FLAKE"
else
  ui_ok "Using the latest stable-channel: $cur"
fi

ui_head "Proton-GE"
bash "$REPO/pkgs/proton-ge/bump.sh"

ui_head "nixlypkgs"
bash "$REPO/scripts/bump-nixlypkgs.sh"

ui_head "Flake inputs"
# The retry round below needs the old revisions to roll back just the failing input.
lockbak=$(mktemp -t nixlyos-lock.XXXXXX)
cp "$REPO/flake.lock" "$lockbak"

# The lock diff is noise, so it is only printed when the command fails.
if ! lockdiff=$(nix flake update --refresh --flake "$REPO" 2>&1); then
  printf '%s\n' "$lockdiff" >&2
  exit 1
fi
updated=$(grep -oP "^• Updated input '\K[^'/]+(?=')" <<<"$lockdiff" | tr '\n' ' ' || true)
[ -n "$updated" ] && ui_ok "updated: ${updated% }" || ui_ok "all inputs already current"

# Nothing to build when the config evaluates to the running system, so the whole
# rebuild is skipped: activation scripts are not re-run and no generation is made.
key=$(tree_key)
running=$(readlink -f /run/current-system)

up_to_date() {
  rm -f "$lockbak"
  printf '%s %s\n' "$key" "$running" > "$STAMP"
  ui_head "Rebuild"
  ui_ok "System is already up-to-date. Nothing to do."
  exit 0
}

# Same files and same running system as the last check: the eval can only give the
# same answer, so it is skipped entirely.
skey="" ssys=""
if [ -s "$STAMP" ]; then read -r skey ssys < "$STAMP"; fi
[ "$skey" = "$key" ] && [ "$ssys" = "$running" ] && up_to_date

# Eval only, no build. On eval errors fall through so nixos-rebuild prints them.
if sys=$(nix eval --raw "$REPO#nixosConfigurations.nixlyos.config.system.build.toplevel" 2>/dev/null) &&
   [ "$sys" = "$running" ]; then
  up_to_date
fi

ui_head "Rebuild"
# switch first so everything is usable at once, falling back to boot if activation
# fails. --sudo, not `sudo nixos-rebuild`: eval must run as the user so the fetcher
# can reach private flake inputs over ssh.
# Fixed path so the log can be tailed while the build runs and read afterwards.
# Truncated per run, never deleted.
log="${XDG_STATE_HOME:-$HOME/.local/state}/nixlyos/update.log"
mkdir -p "$(dirname "$log")"
: > "$log"

# Nix names the package it starts on its own line, so the whole output goes to the
# log and the same stream drives the live view in progress.sh.
run_rebuild() {
  nixos-rebuild "$1" --sudo --keep-going --flake "$REPO#nixlyos" 2>&1 |
    tee -a "$log" | bash "$REPO/scripts/progress.sh"
}

rebuild() {
  local -; set -o pipefail
  run_rebuild switch && return 0
  run_rebuild boot && return 2
  return 1
}

# Package names from the drv paths in the error lines; empty on eval failures.
failed_pkgs() {
  grep -E 'error:|failed' "$log" |
    grep -oP "/nix/store/[a-z0-9]{32}-\K[^' ]+(?=\.drv)" | sort -u | tr '\n' ' ' || true
}

ui_info "building (log: $log)"
printf '\n' >&2
rebuild && rc=0 || rc=$?

# The closure is atomic, so one failing package means no generation at all; rolling
# back only the input that owns it lets every other input keep its new revision.
if (( rc == 1 )); then
  failed=$(failed_pkgs)
  culprits=" " revert_proton=0
  for p in $failed; do
    case $p in
      proton-ge*) revert_proton=1;;
      nixly*)     culprits+="nixlypkgs ";;
      *)          culprits+="nixpkgs nixpkgs-unstable ";;
    esac
  done
  keep=()
  for i in $updated; do [[ $culprits == *" $i "* ]] || keep+=("$i"); done

  if [ -n "$failed" ]; then
    ui_warn "failed: ${failed% } — retrying without that source"
    cp "$lockbak" "$REPO/flake.lock"
    (( revert_proton )) && git -C "$REPO" checkout -- pkgs/proton-ge/pin.json || true
    (( ${#keep[@]} > 0 )) && nix flake update --refresh --flake "$REPO" "${keep[@]}" >>"$log" 2>&1 || true
    rebuild && rc=0 || rc=$?
    (( rc == 1 )) || ui_warn "kept at previous version: ${failed% } — everything else updated"
  fi
fi

# Last resort: restore the whole lock file and the proton pin, so the machine at
# least lands on a generation that builds.
if (( rc == 1 )) && ! cmp -s "$lockbak" "$REPO/flake.lock"; then
  cp "$lockbak" "$REPO/flake.lock"
  git -C "$REPO" checkout -- pkgs/proton-ge/pin.json
  rebuild && rc=0 || rc=$?
  (( rc == 1 )) || ui_warn "update rolled back — previous input revisions restored"
fi

rm -f "$lockbak"
printf '\n' >&2
case $rc in
  0) ui_ok "Rebuild successful. Activation successful.";;
  2) ui_warn "Rebuild successful, but activation failed. New generation set for next boot.";;
  *)
    failed=$(failed_pkgs)
    if [ -n "$failed" ]; then
      ui_err "Rebuild failed (failed packages: ${failed% }). Try updating later or remove the failed package."
    else
      cat "$log" >&2
      ui_err "Rebuild failed. Neither switch nor boot completed."
    fi
    ui_info "full log: $log"
    exit 1
    ;;
esac

# switch handles the services it changed itself; nothing is restarted here.
if (( rc == 0 )); then
  # Recorded after the switch, so the next run skips the eval too.
  printf '%s %s\n' "$(tree_key)" "$(readlink -f /run/current-system)" > "$STAMP"

  ui_head "Post-update"

  # bzImage, initrd and the module tree only take effect after a reboot.
  needs_reboot=""
  for part in kernel initrd kernel-modules; do
    [ "$(readlink -f "/run/booted-system/$part" 2>/dev/null)" = \
      "$(readlink -f "/run/current-system/$part" 2>/dev/null)" ] || needs_reboot+="$part "
  done

  # NVIDIA userspace and the kernel module must match, and reloading the module
  # requires the whole session to release the GPU.
  nv_running=$(awk '/NVRM version/ {print $8}' /proc/driver/nvidia/version 2>/dev/null || true)
  nv_new=$(readlink -f /run/current-system/kernel-modules/lib/modules/*/kernel/drivers/video/nvidia.ko* 2>/dev/null |
    grep -oP 'nvidia-kernel-modules-\K[0-9.]+' | head -1 || true)

  if [ -n "$nv_running" ] && [ -n "$nv_new" ] && [ "$nv_running" != "$nv_new" ]; then
    ui_warn "nvidia $nv_running → $nv_new: reboot to load the new kernel module"
  elif [ -n "$needs_reboot" ]; then
    ui_warn "reboot required (${needs_reboot% } changed)"
  else
    ui_ok "everything running the new version — no reboot needed"
  fi
fi

# Auto-commit is toggled from the Git page in nixlycc.
CONF="$HOME/.local/nixlyos/git.conf"
if [ -f "$CONF" ] && grep -qx 'autocommit=1' "$CONF"; then
  ui_head "Auto-commit"
  if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
    git -C "$REPO" add -A
    git -C "$REPO" commit -m "auto: update $(date '+%Y-%m-%d %H:%M')"
  fi
  # The rebuild is already done, so a failed push must not fail the script.
  git -C "$REPO" push && ui_ok "pushed" || ui_warn "push failed"
fi
