#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing AI assistant tools..."

if command -v no-mistakes >/dev/null 2>&1; then
  echo "  no-mistakes already installed"
else
  echo "  Installing no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
fi

if command -v treehouse >/dev/null 2>&1; then
  echo "  treehouse already installed"
else
  echo "  Installing treehouse..."
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

if command -v npm >/dev/null 2>&1; then
  if command -v gnhf >/dev/null 2>&1; then
    echo "  gnhf already installed"
  else
    echo "  Installing gnhf..."
    npm install -g gnhf
  fi
else
  echo "  WARNING: npm not found, skipping gnhf install"
fi

# firstmate isn't a global binary — it's a repo you clone once and launch your
# agent harness inside; it clones the projects you ask it about into its own
# projects/ subdirectory. Keep the one clone under ~/Projects like everything else.
FIRSTMATE_DIR="$HOME/Projects/github.com/kunchenguid/firstmate"
if [[ -d "$FIRSTMATE_DIR" ]]; then
  echo "  firstmate already cloned at $FIRSTMATE_DIR"
else
  echo "  Cloning firstmate to $FIRSTMATE_DIR..."
  mkdir -p "$(dirname "$FIRSTMATE_DIR")"
  git clone https://github.com/kunchenguid/firstmate "$FIRSTMATE_DIR"
fi
