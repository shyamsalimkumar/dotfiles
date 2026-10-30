#!/usr/bin/env bash
# One-time (online) download of the Universal LPC generator's art and data
# (~500 MB) so lpc.py can build characters offline. Only files are read from
# it; none of its code is run. Safe to re-run; `--update` pulls the latest art.
set -euo pipefail

LPC_HOME="${LPC_HOME:-$HOME/.cache/lpc-generator}"
REPO_URL="https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator.git"

if [[ ! -d "$LPC_HOME/.git" ]]; then
  echo "==> Downloading LPC art into $LPC_HOME (about 500 MB)..."
  git clone --depth 1 "$REPO_URL" "$LPC_HOME"
elif [[ "${1:-}" == "--update" ]]; then
  echo "==> Updating LPC art..."
  git -C "$LPC_HOME" pull --ff-only
fi
echo "LPC ready at $LPC_HOME"
