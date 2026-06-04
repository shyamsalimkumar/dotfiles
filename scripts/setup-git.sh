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

echo "==> Setting up git..."
link ".gitconfig"  "$HOME/.gitconfig"
link ".gitignore"  "$HOME/.gitignore"
link ".ssh/config" "$HOME/.ssh/config"

if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  echo "==> Creating ~/.gitconfig.local for user identity..."
  echo "  (see .gitconfig.local.example in the dotfiles repo for reference)"
  read -rp "  Git name:  " git_name
  read -rp "  Git email: " git_email
  cat > "$HOME/.gitconfig.local" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
  echo "  Created ~/.gitconfig.local"
else
  echo "  ~/.gitconfig.local already exists, skipping user identity setup"
fi
