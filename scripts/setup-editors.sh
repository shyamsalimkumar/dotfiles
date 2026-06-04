#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"

link() {
  local src="$DOTFILES_DIR/$1" dst="$2"
  [[ -d "$(dirname "$dst")" ]] || mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "  Linked $1 → $dst"
}

if [[ "$OS" == "Darwin" ]]; then
  VSCODE_DIR="$HOME/Library/Application Support/Code/User"
else
  VSCODE_DIR="$HOME/.config/Code/User"
fi

echo "==> Setting up editors..."
link "vim/vimrc"               "$HOME/.vimrc"
link "nvim/.config/nvim"       "$HOME/.config/nvim"
link "vscode/settings.json"    "$VSCODE_DIR/settings.json"
link "vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"
