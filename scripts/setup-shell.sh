#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

touch "$DOTFILES_DIR/zsh/aliases.work"

echo "==> Setting up shell..."
link "zsh/zshrc"            "$HOME/.zshrc"
link "zsh/aliases.personal" "$HOME/.aliases.personal"
link "zsh/aliases.work"     "$HOME/.aliases.work"
link "helpers/personal"     "$HOME/.local/bin/personal"
link "helpers/work"         "$HOME/.local/bin/work"
