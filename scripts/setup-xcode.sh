#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Skipping Xcode CLI tools — not macOS."
  exit 0
fi

if xcode-select -p &>/dev/null; then
  echo "Xcode Command Line Tools already installed."
  exit 0
fi

echo "==> Installing Xcode Command Line Tools..."
xcode-select --install
echo "After installation completes, re-run this script."
exit 1
