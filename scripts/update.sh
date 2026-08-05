#!/usr/bin/env bash
# Full oppdatering: bump stable-grena om ny NixOS-release finnes,
# bump proton-ge-pin, oppdater ALLE flake-inputs, bygg for neste boot.
set -euo pipefail

REPO="$HOME/.nixlyos"
FLAKE="$REPO/flake.nix"

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

if [ "$new" != "$cur" ]; then
  echo "stable: $cur -> $new"
  sed -i "s|nixpkgs/nixos-$cur|nixpkgs/nixos-$new|; s|home-manager/release-$cur|home-manager/release-$new|" "$FLAKE"
else
  echo "stable: $cur (nyeste)"
fi

bash "$REPO/pkgs/proton-ge/bump.sh"
nix flake update --flake "$REPO"
sudo nixos-rebuild boot --flake "$REPO#nixlyos"

# Auto-commit: styres av "Auto commit changes" paa Git-siden i nixlycc.
CONF="$HOME/.local/nixlyos/git.conf"
if [ -f "$CONF" ] && grep -qx 'autocommit=1' "$CONF"; then
  if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
    git -C "$REPO" add -A
    git -C "$REPO" commit -m "auto: update $(date '+%Y-%m-%d %H:%M')"
  fi
  # Rebuild er allerede ferdig — en feilet push skal ikke felle skriptet.
  git -C "$REPO" push || echo "auto-commit: push feilet"
fi
