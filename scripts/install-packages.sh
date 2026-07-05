#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

trust_taps() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local tap
  while read -r tap; do
    case "$tap" in
      homebrew/bundle|homebrew/core|homebrew/cask) continue ;;
    esac
    if brew trust --tap "$tap" >/dev/null 2>&1; then
      echo "  Trusted tap: $tap"
    else
      echo "  WARNING: could not auto-trust tap '$tap'. If installs from it fail, run: brew trust --tap $tap"
    fi
  done < <(grep -oE '^tap "[^"]+"' "$file" | sed -E 's/^tap "([^"]+)"$/\1/')
  return 0
}

echo "==> Trusting third-party taps..."
trust_taps "$DOTFILES_DIR/Brewfile"
if [[ "$OS" == "Darwin" ]]; then
  trust_taps "$DOTFILES_DIR/Brewfile.mac"
fi

echo "==> Installing common packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

if [[ "$OS" == "Darwin" ]]; then
  echo "==> Installing macOS-specific packages..."
  brew bundle --file="$DOTFILES_DIR/Brewfile.mac"
fi

if [[ -s "$DOTFILES_DIR/npm-globals.txt" ]] && command -v npm >/dev/null 2>&1; then
  echo "==> Installing global npm packages..."
  xargs npm install -g < "$DOTFILES_DIR/npm-globals.txt"
fi
