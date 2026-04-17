#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# ── OS check ──────────────────────────────────────────────────────────────────
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS. Only macOS and Linux are supported."
  exit 1
fi

echo "==> Setting up dotfiles on $OS..."

# ── macOS: Xcode CLI tools ────────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  if ! xcode-select -p &>/dev/null; then
    echo "==> Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "After installation completes, re-run this script."
    exit 0
  fi
fi

# ── Linux: Homebrew prerequisites ────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
  if command -v apt-get &>/dev/null; then
    echo "==> Installing Homebrew prerequisites..."
    sudo apt-get update -qq
    sudo apt-get install -y build-essential procps curl file git
  fi
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to PATH (location differs by OS and architecture)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ── Homebrew packages ─────────────────────────────────────────────────────────
echo "==> Installing common packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock

if [[ "$OS" == "Darwin" ]]; then
  echo "==> Installing macOS-specific packages..."
  brew bundle --file="$DOTFILES_DIR/Brewfile.mac" --no-lock
fi

# ── Symlinks ──────────────────────────────────────────────────────────────────
link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  [[ -d "$dst_dir" ]] || mkdir -p "$dst_dir"

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -sfn "$src" "$dst"
  echo "  Linked $1 → $dst"
}

touch "$DOTFILES_DIR/zsh/aliases.work"

echo "==> Creating symlinks..."
link ".gitconfig"        "$HOME/.gitconfig"
link ".gitignore"        "$HOME/.gitignore"
link ".ssh/config"       "$HOME/.ssh/config"
link "zsh/zshrc"             "$HOME/.zshrc"
link "zsh/aliases.personal"  "$HOME/.aliases.personal"
link "zsh/aliases.work"      "$HOME/.aliases.work"
link "vim/vimrc"         "$HOME/.vimrc"
link "nvim/.config/nvim" "$HOME/.config/nvim"

# VS Code config path differs by OS
if [[ "$OS" == "Darwin" ]]; then
  VSCODE_DIR="$HOME/Library/Application Support/Code/User"
else
  VSCODE_DIR="$HOME/.config/Code/User"
fi
link "vscode/settings.json"    "$VSCODE_DIR/settings.json"
link "vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"
link "helpers/personal"        "$HOME/.local/bin/personal"
link "helpers/work"            "$HOME/.local/bin/work"
link "claude/CLAUDE.md"             "$HOME/.claude/CLAUDE.md"
link "claude/settings.json"         "$HOME/.claude/settings.json"
link "claude/settings.local.json"   "$HOME/.claude/settings.local.json"
link "claude/keybindings.json"      "$HOME/.claude/keybindings.json"
link "claude/skills"                "$HOME/.claude/skills"
link "claude/commands"              "$HOME/.claude/commands"
link "claude/hooks"                 "$HOME/.claude/hooks"
link "claude/agents"                "$HOME/.claude/agents"
link "claude/rules"                 "$HOME/.claude/rules"

echo ""
echo "Done! Restart your terminal or run: source ~/.zshrc"
