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

echo "==> Setting up Claude Code..."
link "claude/CLAUDE.md"           "$HOME/.claude/CLAUDE.md"
link "claude/settings.json"       "$HOME/.claude/settings.json"
link "claude/settings.local.json" "$HOME/.claude/settings.local.json"
link "claude/keybindings.json"    "$HOME/.claude/keybindings.json"
link "claude/skills"              "$HOME/.claude/skills"
link "claude/commands"            "$HOME/.claude/commands"
link "claude/hooks"               "$HOME/.claude/hooks"
link "claude/agents"              "$HOME/.claude/agents"
link "claude/rules"               "$HOME/.claude/rules"

if ! command -v claude &>/dev/null; then
  echo "  Skipping plugins (claude CLI not found — install claude-code first)."
  exit 0
fi

plugins=$(jq -r '.enabledPlugins | to_entries[] | select(.value == true) | .key' \
  "$DOTFILES_DIR/claude/settings.json" 2>/dev/null || true)

if [[ -z "$plugins" ]]; then
  echo "  No plugins defined in claude/settings.json"
  exit 0
fi

installed_json="$HOME/.claude/plugins/installed_plugins.json"

while IFS= read -r plugin; do
  if [[ -f "$installed_json" ]] && jq -e --arg p "$plugin" '.plugins[$p]' "$installed_json" &>/dev/null; then
    echo "  Already installed: $plugin"
    continue
  fi
  echo "  Installing plugin: $plugin"
  if ! claude plugin install "$plugin" --yes 2>&1; then
    echo "  Warning: failed to install $plugin"
  fi
done <<< "$plugins"
