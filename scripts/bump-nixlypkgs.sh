#!/usr/bin/env bash
# Bump every aCeTotal package in nixlypkgs to upstream HEAD, then commit and push
# so a later `nix flake update` picks them up.
set -euo pipefail

NP="$HOME/git/nixlypkgs"
. "$HOME/.nixlyos/scripts/ui.sh"

if [ ! -d "$NP/.git" ]; then
  ui_warn "$NP missing, skipping"
  exit 0
fi
if [ -n "$(git -C "$NP" status --porcelain)" ]; then
  ui_warn "uncommitted changes in $NP, skipping"
  exit 0
fi

git -C "$NP" pull --ff-only -q

bumped=()
for f in "$NP"/pkgs/*/default.nix; do
  grep -q 'fetchFromGitHub' "$f" || continue
  owner=$(grep -oP 'owner = "\K[^"]+' "$f" | head -1)
  [ "$owner" = "aCeTotal" ] || continue
  repo=$(grep -oP 'repo = "\K[^"]+' "$f" | head -1)
  old=$(grep -oP 'rev = "\K[0-9a-f]{40}' "$f" | head -1)

  new=$(git ls-remote "https://github.com/aCeTotal/$repo" HEAD | cut -f1)
  if [ -z "$new" ]; then
    ui_warn "$repo: failed to fetch HEAD, skipping"
    continue
  fi
  if [ "$new" = "$old" ]; then
    continue
  fi

  ui_ok "$repo: ${old:0:7} → ${new:0:7}"
  sha=$(nix-prefetch-url --unpack "https://github.com/aCeTotal/$repo/archive/$new.tar.gz" 2>/dev/null)
  sri=$(nix hash convert --hash-algo sha256 --to sri "$sha")
  oldhash=$(grep -oP 'hash = "\Ksha256-[^"]+' "$f" | head -1)
  sed -i "s|$old|$new|; s|$oldhash|$sri|" "$f"

  # cargoHash changes with Cargo.lock, so build once, read the correct hash out of
  # the mismatch error, patch it and rebuild to verify.
  if grep -q 'cargoHash' "$f"; then
    pkg=$(basename "$(dirname "$f")")
    if ! out=$(nix build "$NP#$pkg" --no-link 2>&1); then
      got=$(grep -oP 'got:\s+\Ksha256-\S+' <<<"$out" | head -1)
      if [ -z "$got" ]; then
        printf '%s\n' "$out" >&2
        ui_err "$repo: build failed without hash mismatch"
        exit 1
      fi
      oldcargo=$(grep -oP 'cargoHash = "\K[^"]+' "$f")
      sed -i "s|$oldcargo|$got|" "$f"
      nix build "$NP#$pkg" --no-link
    fi
  fi
  bumped+=("$repo")
done

if [ ${#bumped[@]} -gt 0 ]; then
  git -C "$NP" add -A
  git -C "$NP" commit -q -m "auto: bump ${bumped[*]}"
  git -C "$NP" push -q
  ui_ok "pushed: ${bumped[*]}"
else
  ui_ok "all packages already at upstream HEAD"
fi
