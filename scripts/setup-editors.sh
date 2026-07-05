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
link "vim/vimrc"                      "$HOME/.vimrc"
link "nvim/.config/nvim"              "$HOME/.config/nvim"
link "wezterm/.config/wezterm"        "$HOME/.config/wezterm"
link "tmux/.config/tmux"              "$HOME/.config/tmux"
link "starship/.config/starship.toml" "$HOME/.config/starship.toml"
link "vscode/settings.json"           "$VSCODE_DIR/settings.json"
link "vscode/keybindings.json"        "$VSCODE_DIR/keybindings.json"

# Neovim's Python 3 provider (needed by deoplete etc.) — a dedicated venv avoids
# PEP 668 "externally-managed-environment" errors from pip installing into system python.
NVIM_VENV="$HOME/.local/share/nvim/venv"
if command -v nvim >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  if [[ ! -x "$NVIM_VENV/bin/python3" ]]; then
    echo "  Creating Neovim Python 3 provider venv..."
    python3 -m venv "$NVIM_VENV"
  fi
  "$NVIM_VENV/bin/pip" install --upgrade --quiet pip pynvim
fi

if command -v nvim >/dev/null 2>&1; then
  echo "  Installing/updating Neovim plugins..."
  nvim --headless -c 'PlugInstall! --sync' -c 'UpdateRemotePlugins' -c 'qa' 2>&1 | tail -5 || true
fi
