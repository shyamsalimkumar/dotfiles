#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo "==> Installing common packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock

if [[ "$OS" == "Darwin" ]]; then
  echo "==> Installing macOS-specific packages..."
  brew bundle --file="$DOTFILES_DIR/Brewfile.mac" --no-lock
fi
