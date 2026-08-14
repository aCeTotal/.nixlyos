#!/usr/bin/env bash
# Bump alle aCeTotal-pakker i nixlypkgs (rev + hash) til nyeste upstream-HEAD,
# commit + push nixlypkgs slik at `nix flake update` etterpaa plukker dem opp.
set -euo pipefail

NP="$HOME/git/nixlypkgs"

if [ ! -d "$NP/.git" ]; then
  echo "nixlypkgs: $NP missing, skipping" >&2
  exit 0
fi
if [ -n "$(git -C "$NP" status --porcelain)" ]; then
  echo "nixlypkgs: uncommitted changes in $NP, skipping" >&2
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
    echo "nixlypkgs: $repo: failed to fetch HEAD, skipping" >&2
    continue
  fi
  if [ "$new" = "$old" ]; then
    echo "$repo: ${old:0:7} (Latest)"
    continue
  fi

  echo "$repo: ${old:0:7} -> ${new:0:7}"
  sha=$(nix-prefetch-url --unpack "https://github.com/aCeTotal/$repo/archive/$new.tar.gz" 2>/dev/null)
  sri=$(nix hash convert --hash-algo sha256 --to sri "$sha")
  oldhash=$(grep -oP 'hash = "\Ksha256-[^"]+' "$f" | head -1)
  sed -i "s|$old|$new|; s|$oldhash|$sri|" "$f"

  # cargoHash endres naar Cargo.lock endres: proevebygg, les riktig hash
  # ut av mismatch-feilen, patch og verifiser med nytt bygg.
  if grep -q 'cargoHash' "$f"; then
    pkg=$(basename "$(dirname "$f")")
    if ! out=$(nix build "$NP#$pkg" --no-link 2>&1); then
      got=$(grep -oP 'got:\s+\Ksha256-\S+' <<<"$out" | head -1)
      if [ -z "$got" ]; then
        echo "$out" >&2
        echo "nixlypkgs: $repo: build failed without hash mismatch" >&2
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
  echo "nixlypkgs: updated ${bumped[*]}"
fi
