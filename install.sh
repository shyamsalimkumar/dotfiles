#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS. Only macOS and Linux are supported."
  exit 1
fi

echo "==> Setting up dotfiles on $OS..."

"$DOTFILES_DIR/scripts/setup-xcode.sh"
"$DOTFILES_DIR/scripts/setup-brew.sh"
"$DOTFILES_DIR/scripts/install-packages.sh"
"$DOTFILES_DIR/scripts/setup-projects.sh"
"$DOTFILES_DIR/scripts/setup-ai-tools.sh"
"$DOTFILES_DIR/scripts/setup-symlinks.sh"

echo ""
echo "Done! Restart your terminal or run: source ~/.zshrc"
