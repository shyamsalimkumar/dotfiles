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
link "claude/output-styles"       "$HOME/.claude/output-styles"

# Reconcile skills installed via `npx skills add ... -g` (see README "Manual
# step") against claude/skills/ — that installer isn't reliably leaving the
# symlink in place, so treat ~/.agents/skills as the source of truth and
# self-heal here on every run instead of trusting it to persist. Skills
# already provided by a Claude Code plugin (mattpocock-skills,
# andrej-karpathy-skills) are skipped here — claude/skills/ is this repo's
# working tree, and duplicating a plugin skill there both fights the plugin
# and (since it's a real directory, not gitignored) risks clobbering a
# tracked file if the name happens to collide with one.
plugin_skill_names=$(find "$HOME/.claude/plugins/marketplaces"/*/skills -iname "SKILL.md" 2>/dev/null \
  | xargs -n1 dirname 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u)

agents_skills_dir="$HOME/.agents/skills"
if [[ -d "$agents_skills_dir" ]]; then
  for skill_src in "$agents_skills_dir"/*/; do
    name="$(basename "$skill_src")"
    # no-mistakes is dropped directly by its own installer (see
    # scripts/setup-ai-tools.sh), not by `npx skills add` — leave it alone
    # even though a same-named copy also happens to exist here.
    if [[ "$name" != "no-mistakes" ]] && ! grep -qxF "$name" <<< "$plugin_skill_names"; then
      target="$HOME/.claude/skills/$name"
      if [[ -e "$target" && ! -L "$target" ]]; then
        echo "  Backing up existing $target → ${target}.bak"
        mv "$target" "${target}.bak"
      fi
      ln -sfn "$skill_src" "$target"
      echo "  Linked global skill: $name"
      ignore_line="claude/skills/$name"
      grep -qxF "$ignore_line" "$DOTFILES_DIR/.gitignore" || echo "$ignore_line" >> "$DOTFILES_DIR/.gitignore"
    fi

    # Pi has no plugin/marketplace system, so it needs every skill
    # (including mattpocock's and karpathy-guidelines) linked directly —
    # its skills dir isn't part of this repo, so there's no clobbering risk.
    if [[ "$name" != "no-mistakes" ]] && command -v pi &>/dev/null; then
      pi_target="$HOME/.pi/agent/skills/$name"
      mkdir -p "$HOME/.pi/agent/skills"
      if [[ -e "$pi_target" && ! -L "$pi_target" ]]; then
        echo "  Backing up existing $pi_target → ${pi_target}.bak"
        mv "$pi_target" "${pi_target}.bak"
      fi
      ln -sfn "$skill_src" "$pi_target"
      echo "  Linked global skill for Pi: $name"
    fi
  done
fi

if ! command -v claude &>/dev/null; then
  echo "  Skipping plugins (claude CLI not found — install claude-code first)."
  exit 0
fi

# mattpocock-skills and andrej-karpathy-skills live in third-party
# marketplaces, not the default claude-plugins-official one — make sure
# both are registered before the install loop below tries to resolve them.
if ! claude plugin marketplace list 2>/dev/null | grep -q "mattpocock"; then
  claude plugin marketplace add mattpocock/skills 2>&1 || true
fi
if ! claude plugin marketplace list 2>/dev/null | grep -q "karpathy-skills"; then
  claude plugin marketplace add multica-ai/andrej-karpathy-skills 2>&1 || true
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
