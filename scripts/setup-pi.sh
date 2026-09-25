#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_AGENT_DIR="$HOME/.pi/agent"

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

# Links each entry inside a repo dir individually into a real target directory,
# instead of symlinking the whole directory. ~/.pi/agent/skills in particular
# also receives entries mirrored from ~/.agents/skills by setup-claude.sh, so it
# must stay a real directory rather than a symlink to pi/skills.
link_entries() {
  local repo_subdir="$1" target_dir="$2"
  local src_dir="$DOTFILES_DIR/$repo_subdir"
  [[ -d "$src_dir" ]] || return 0
  mkdir -p "$target_dir"
  for entry in "$src_dir"/*; do
    local name
    name="$(basename "$entry")"
    [[ "$name" == ".gitkeep" ]] && continue
    link "$repo_subdir/$name" "$target_dir/$name"
  done
}

echo "==> Setting up Pi..."
link "pi/settings.json"    "$PI_AGENT_DIR/settings.json"
link "pi/keybindings.json" "$PI_AGENT_DIR/keybindings.json"
link "claude/AGENTS.md"    "$PI_AGENT_DIR/AGENTS.md"

link_entries "pi/extensions" "$PI_AGENT_DIR/extensions"
link_entries "pi/skills"     "$PI_AGENT_DIR/skills"
link_entries "pi/prompts"    "$PI_AGENT_DIR/prompts"
