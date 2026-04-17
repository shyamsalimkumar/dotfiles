#!/usr/bin/env bash
# Superseded by install.sh — kept for quick standalone symlink setup
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ln -sfn "$DIR/.gitconfig"        "$HOME/.gitconfig"
ln -sfn "$DIR/.gitignore"        "$HOME/.gitignore"
ln -sfn "$DIR/.ssh/config"       "$HOME/.ssh/config"
ln -sfn "$DIR/zsh/zshrc"             "$HOME/.zshrc"
ln -sfn "$DIR/zsh/aliases.personal"  "$HOME/.aliases.personal"
ln -sfn "$DIR/zsh/aliases.work"      "$HOME/.aliases.work"
ln -sfn "$DIR/vim/vimrc"         "$HOME/.vimrc"
ln -sfn "$DIR/nvim/.config/nvim"       "$HOME/.config/nvim"
ln -sfn "$DIR/vscode/settings.json"    "$HOME/Library/Application Support/Code/User/settings.json"
ln -sfn "$DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
ln -sfn "$DIR/helpers/personal"        "$HOME/.local/bin/personal"
ln -sfn "$DIR/helpers/work"            "$HOME/.local/bin/work"
ln -sfn "$DIR/claude/CLAUDE.md"           "$HOME/.claude/CLAUDE.md"
ln -sfn "$DIR/claude/settings.json"       "$HOME/.claude/settings.json"
ln -sfn "$DIR/claude/settings.local.json" "$HOME/.claude/settings.local.json"
ln -sfn "$DIR/claude/keybindings.json"    "$HOME/.claude/keybindings.json"
ln -sfn "$DIR/claude/skills"              "$HOME/.claude/skills"
ln -sfn "$DIR/claude/commands"            "$HOME/.claude/commands"
ln -sfn "$DIR/claude/hooks"               "$HOME/.claude/hooks"
ln -sfn "$DIR/claude/agents"              "$HOME/.claude/agents"
ln -sfn "$DIR/claude/rules"               "$HOME/.claude/rules"
