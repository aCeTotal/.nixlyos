#!/usr/bin/env bash
# Full oppdatering: bump stable-grena om ny NixOS-release finnes,
# bump proton-ge-pin, oppdater ALLE flake-inputs, bygg for neste boot.
set -euo pipefail

REPO="$HOME/.nixlyos"
FLAKE="$REPO/flake.nix"
. "$REPO/scripts/ui.sh"

# Passordet spoerres FOERST, ikke etter en halvtime med bygging. Bakgrunns-
# loopen holder sudo-timestampen varm saa `nixos-rebuild --sudo` til slutt
# ikke rekker aa timeoute (default 5 min).
ui_head "NixlyOS update"
sudo -v
while sudo -n true 2>/dev/null; do sleep 50; done &
sudo_keepalive=$!
trap 'kill "$sudo_keepalive" 2>/dev/null' EXIT

ui_head "Hardware"
# CPU/GPU-imports i modules/core/default.nix maa matche maskinen FOER eval.
bash "$REPO/scripts/detect-hw.sh" "$REPO"

cur=$(grep -oP 'nixpkgs/nixos-\K[0-9]{2}\.[0-9]{2}' "$FLAKE")

# 25.11 -> 26.05 -> 26.11 -> 27.05 ...
next_ver() {
  local y=${1%%.*} m=${1##*.}
  if [ "$m" = "05" ]; then echo "$y.11"; else printf '%02d.05\n' $((10#$y + 1)); fi
}

has_branch() { git ls-remote --exit-code --heads "$1" "$2" >/dev/null 2>&1; }

# Hopper bare til en ny release naar BEGGE grenene finnes — home-manager
# mot feil nixpkgs-base brekker evalueringen.
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
# Lock-diffen er stoey (to linjer med rev+narHash per input). Fanges opp og
# vises bare naar kommandoen feiler; ellers oppsummeres den.
if ! lockdiff=$(nix flake update --refresh --flake "$REPO" 2>&1); then
  printf '%s\n' "$lockdiff" >&2
  exit 1
fi
updated=$(grep -oP "^• Updated input '\K[^'/]+(?=')" <<<"$lockdiff" | tr '\n' ' ' || true)
[ -n "$updated" ] && ui_ok "updated: ${updated% }" || ui_ok "all inputs already current"

ui_head "Rebuild"
# --sudo, ikke `sudo nixos-rebuild`: evalueringen maa skje som bruker, ellers
# naar ikke fetcheren private flake-inputs over ssh. Kun aktivering blir root.
nixos-rebuild boot --sudo --flake "$REPO#nixlyos"

# Auto-commit: styres av "Auto commit changes" paa Git-siden i nixlycc.
CONF="$HOME/.local/nixlyos/git.conf"
if [ -f "$CONF" ] && grep -qx 'autocommit=1' "$CONF"; then
  ui_head "Auto-commit"
  if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
    git -C "$REPO" add -A
    git -C "$REPO" commit -m "auto: update $(date '+%Y-%m-%d %H:%M')"
  fi
  # Rebuild er allerede ferdig — en feilet push skal ikke felle skriptet.
  git -C "$REPO" push && ui_ok "pushed" || ui_warn "push failed"
fi
