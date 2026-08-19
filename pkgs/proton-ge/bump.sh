#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$(readlink -f "$0")")"
. "$(dirname "$DIR")/../scripts/ui.sh"
PIN="$DIR/pin.json"
REPO="GloriousEggroll/proton-ge-custom"

VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
[[ -z "$VERSION" || "$VERSION" == "null" ]] && { ui_err "failed to fetch latest tag"; exit 1; }

if [[ -f "$PIN" ]] && [[ "$(jq -r '.version' "$PIN")" == "$VERSION" ]]; then
  ui_ok "$VERSION (latest)"
  exit 0
fi

URL="https://github.com/${REPO}/releases/download/${VERSION}/${VERSION}-x86_64.tar.gz"
ui_info "bumping to $VERSION"
SHA=$(nix-prefetch-url --unpack --type sha256 "$URL" 2>/dev/null)
HASH=$(nix hash convert --hash-algo sha256 --to sri "$SHA")

jq -n --arg v "$VERSION" --arg h "$HASH" '{version: $v, hash: $h}' > "$PIN"
ui_ok "updated to $VERSION"
