#!/usr/bin/env bash
# Full update: bump the stable branch if a new NixOS release exists, update
# every flake input (chaotic-nyx carries the prebuilt CachyOS kernel and
# Proton-CachyOS) and build for the next boot.
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
tmp=$(mktemp -d -t nixlyos.XXXXXX)
trap 'kill -- -"$sudo_keepalive" 2>/dev/null; rm -rf "$tmp"' EXIT

STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/nixlyos/last-build"
mkdir -p "$(dirname "$STAMP")"

# Flake eval only sees tracked files, so their contents plus the running system
# identify the last known result. 14 ms, against 11 s for the eval it replaces.
# cd, because ls-files prints paths relative to the repo, not to the caller's cwd.
tree_key() { (cd "$REPO" && git ls-files -z | xargs -0 sha1sum) | sha1sum | cut -d' ' -f1; }

# Everything without an ordering dependency starts immediately and is collected
# where its result is needed: the two branch listings feed the channel bump
# (which must precede the flake update), detect-hw only has to finish before
# the eval. One ls-remote per repo lists every release branch at once, instead
# of one round-trip per candidate version.
git ls-remote --heads https://github.com/NixOS/nixpkgs 'nixos-[0-9]*' >"$tmp/np" 2>/dev/null &
np_pid=$!
git ls-remote --heads https://github.com/nix-community/home-manager 'release-*' >"$tmp/hm" 2>/dev/null &
hm_pid=$!
# The cpu/gpu imports must match the machine before eval.
bash "$REPO/scripts/detect-hw.sh" "$REPO" >"$tmp/hw" 2>&1 &
hw_pid=$!

ui_head "nixlypkgs"
bash "$REPO/scripts/bump-nixlypkgs.sh"

cur=$(grep -oP 'nixpkgs/nixos-\K[0-9]{2}\.[0-9]{2}' "$FLAKE")

# 25.11 -> 26.05 -> 26.11 -> 27.05 ...
next_ver() {
  local y=${1%%.*} m=${1##*.}
  if [ "$m" = "05" ]; then echo "$y.11"; else printf '%02d.05\n' $((10#$y + 1)); fi
}

ui_head "Nixpkgs-channel"
wait "$np_pid" || true
wait "$hm_pid" || true
# Only jump releases when both branches exist; home-manager against the wrong
# nixpkgs base breaks eval. Offline both files are empty, so the channel stays.
new=$cur
while cand=$(next_ver "$new") &&
      grep -q "refs/heads/nixos-$cand\$" "$tmp/np" &&
      grep -q "refs/heads/release-$cand\$" "$tmp/hm"; do
  new=$cand
done
if [ "$new" != "$cur" ]; then
  ui_ok "Bumped channel from $cur to the newest: $new"
  sed -i "s|nixpkgs/nixos-$cur|nixpkgs/nixos-$new|; s|home-manager/release-$cur|home-manager/release-$new|" "$FLAKE"
else
  ui_ok "Using the latest stable-channel: $cur"
fi

ui_head "Flake inputs"
# The retry round below needs the old revisions to roll back just the failing input.
lockbak="$tmp/flake.lock"
cp "$REPO/flake.lock" "$lockbak"

# The lock diff is noise, so it is only printed when the command fails.
if ! lockdiff=$(nix flake update --refresh --flake "$REPO" 2>&1); then
  printf '%s\n' "$lockdiff" >&2
  exit 1
fi
updated=$(grep -oP "^• Updated input '\K[^'/]+(?=')" <<<"$lockdiff" | tr '\n' ' ' || true)
[ -n "$updated" ] && ui_ok "updated: ${updated% }" || ui_ok "all inputs already current"

ui_head "Hardware"
if ! wait "$hw_pid"; then
  cat "$tmp/hw" >&2
  ui_err "hardware detection failed"
  exit 1
fi
cat "$tmp/hw" >&2

key=$(tree_key)
running=$(readlink -f /run/current-system)

up_to_date() {
  printf '%s %s\n' "$key" "$running" > "$STAMP"
  ui_ok "System is already up-to-date. Nothing to do."
  exit 0
}

ui_head "Rebuild"
# Same files and same running system as the last check: the eval can only give the
# same answer, so it is skipped entirely.
skey="" ssys=""
if [ -s "$STAMP" ]; then read -r skey ssys < "$STAMP"; fi
[ "$skey" = "$key" ] && [ "$ssys" = "$running" ] && up_to_date

# Fixed path so the log can be tailed while the build runs and read afterwards.
# Truncated per run, never deleted.
log="${XDG_STATE_HOME:-$HOME/.local/state}/nixlyos/update.log"
mkdir -p "$(dirname "$log")"
: > "$log"

ATTR="$REPO#nixosConfigurations.nixlyos.config.system.build.toplevel"

# One nix build does eval and build in a single pass — nixos-rebuild would eval
# a second time on top of the up-to-date check. Built as the user so the fetcher
# can reach private flake inputs over ssh; only profile-set and activation run
# as root. stdout carries the out path into a file, stderr the raw build lines
# into the log and the live view.
build_sys() {
  local -; set -o pipefail
  nix build --no-link --print-out-paths --keep-going "$ATTR" \
    2>&1 1>"$tmp/out" | tee -a "$log" | bash "$REPO/scripts/progress.sh"
}

# switch-to-configuration inside a transient unit, like nixos-rebuild does, so
# activation survives if it restarts the very session this script runs in.
activate() { # switch|boot
  local -; set -o pipefail
  sudo systemd-run --collect --no-ask-password --pipe --quiet --wait \
    --service-type=exec --unit="nixlyos-$1-$$" \
    "$sys/bin/switch-to-configuration" "$1" 2>&1 |
    tee -a "$log" | bash "$REPO/scripts/progress.sh" --activate
}

# 0 activated, 2 built but only set for next boot, 3 nothing new, 1 failed.
rebuild() {
  build_sys || return 1
  sys=$(<"$tmp/out")
  [ "$sys" = "$running" ] && return 3
  # Profile first, so the bootloader entry exists before activation.
  sudo nix-env -p /nix/var/nix/profiles/system --set "$sys" || return 1
  activate switch && return 0
  activate boot && return 2
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
(( rc == 3 )) && up_to_date

# The closure is atomic, so one failing package means no generation at all; rolling
# back only the input that owns it lets every other input keep its new revision.
if (( rc == 1 )); then
  failed=$(failed_pkgs)
  culprits=" "
  for p in $failed; do
    case $p in
      proton-cachyos*|nvidia-x11*|nvidia-kernel-modules*|linux-[0-9]*)
                  culprits+="chaotic ";;
      nixly*)     culprits+="nixlypkgs ";;
      *)          culprits+="nixpkgs nixpkgs-unstable ";;
    esac
  done
  keep=()
  for i in $updated; do [[ $culprits == *" $i "* ]] || keep+=("$i"); done

  if [ -n "$failed" ]; then
    ui_warn "failed: ${failed% } — retrying without that source"
    cp "$lockbak" "$REPO/flake.lock"
    (( ${#keep[@]} > 0 )) && nix flake update --refresh --flake "$REPO" "${keep[@]}" >>"$log" 2>&1 || true
    rebuild && rc=0 || rc=$?
    (( rc == 3 )) && rc=0
    (( rc == 1 )) || ui_warn "kept at previous version: ${failed% } — everything else updated"
  fi
fi

# Last resort: restore the whole lock file, so the machine at least lands on a
# generation that builds.
if (( rc == 1 )) && ! cmp -s "$lockbak" "$REPO/flake.lock"; then
  cp "$lockbak" "$REPO/flake.lock"
  rebuild && rc=0 || rc=$?
  (( rc == 3 )) && rc=0
  (( rc == 1 )) || ui_warn "update rolled back — previous input revisions restored"
fi

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
