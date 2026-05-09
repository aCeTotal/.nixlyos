#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$(readlink -f "$0")")"
PIN="$DIR/pin.json"
REPO="GloriousEggroll/proton-ge-custom"

VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
[[ -z "$VERSION" || "$VERSION" == "null" ]] && { echo "proton-ge bump: failed to fetch latest tag" >&2; exit 1; }

if [[ -f "$PIN" ]] && [[ "$(jq -r '.version' "$PIN")" == "$VERSION" ]]; then
  echo "proton-ge-bin: already at $VERSION"
  exit 0
fi

URL="https://github.com/${REPO}/releases/download/${VERSION}/${VERSION}.tar.gz"
echo "proton-ge-bin: bumping to $VERSION"
SHA=$(nix-prefetch-url --type sha256 "$URL" 2>/dev/null)
HASH=$(nix hash convert --hash-algo sha256 --to sri "$SHA")

jq -n --arg v "$VERSION" --arg h "$HASH" '{version: $v, hash: $h}' > "$PIN"
echo "proton-ge-bin: pinned $VERSION ($HASH)"
