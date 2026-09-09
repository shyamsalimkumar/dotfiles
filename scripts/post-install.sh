#!/usr/bin/env bash
# Post-installation tasks for Nix-based dotfiles
# Run this after: darwin-rebuild switch --flake ~/.config/nix-darwin (macOS)
# or: home-manager switch --flake ~/.config/home-manager (Linux/WSL)

set -euo pipefail

OS="$(uname -s)"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Running post-installation tasks..."

# ============================================================================
# Git local configuration
# ============================================================================
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  echo ""
  echo "==> Creating ~/.gitconfig.local for user identity..."
  echo "  (see .gitconfig.local.example in the dotfiles repo for reference)"
  read -rp "  Git name:  " git_name
  read -rp "  Git email: " git_email
  cat > "$HOME/.gitconfig.local" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
  echo "  ✓ Created ~/.gitconfig.local"
else
  echo "  ✓ ~/.gitconfig.local already exists"
fi

# ============================================================================
# Neovim plugin sync
# ============================================================================
if command -v nvim >/dev/null 2>&1; then
  echo ""
  echo "==> Syncing Neovim plugins..."
  if nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5; then
    echo "  ✓ Neovim plugins synced"
  else
    echo "  ⚠ Neovim plugin sync had warnings (this is often normal)"
  fi
else
  echo ""
  echo "  ⚠ Neovim not found, skipping plugin sync"
fi

# ============================================================================
# Claude plugin installation
# ============================================================================
if command -v claude &>/dev/null; then
  echo ""
  echo "==> Installing Claude plugins..."

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
    echo "  ⚠ No plugins defined in claude/settings.json"
  else
    installed_json="$HOME/.claude/plugins/installed_plugins.json"

    while IFS= read -r plugin; do
      if [[ -f "$installed_json" ]] && jq -e --arg p "$plugin" '.plugins[$p]' "$installed_json" &>/dev/null; then
        echo "  ✓ Already installed: $plugin"
        continue
      fi
      echo "  Installing plugin: $plugin"
      if ! claude plugin install "$plugin" --yes 2>&1; then
        echo "  ⚠ Failed to install $plugin"
      fi
    done <<< "$plugins"
  fi
else
  echo ""
  echo "  ⚠ Claude CLI not found, skipping plugin installation"
  echo "    Install claude-code first, then re-run this script"
fi

# ============================================================================
# Pi skills
# ============================================================================
# Pi (npm-globals.txt) has no plugin/marketplace system like Claude Code
# does, so skills installed via `npx skills add ... -g` (see README "Manual
# step") need to be mirrored into its skills directory directly. Treats
# ~/.agents/skills as the source of truth and self-heals here on every run,
# same as Claude Code's skill reconciliation in scripts/setup-claude.sh.
if command -v pi &>/dev/null; then
  echo ""
  echo "==> Linking global skills for Pi..."
  agents_skills_dir="$HOME/.agents/skills"
  if [[ -d "$agents_skills_dir" ]]; then
    mkdir -p "$HOME/.pi/agent/skills"
    for skill_src in "$agents_skills_dir"/*/; do
      name="$(basename "$skill_src")"
      [[ "$name" == "no-mistakes" ]] && continue
      pi_target="$HOME/.pi/agent/skills/$name"
      if [[ -e "$pi_target" && ! -L "$pi_target" ]]; then
        echo "  Backing up existing $pi_target → ${pi_target}.bak"
        mv "$pi_target" "${pi_target}.bak"
      fi
      ln -sfn "$skill_src" "$pi_target"
      echo "  ✓ Linked global skill for Pi: $name"
    done
  fi
fi

echo ""
echo "==> Post-installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal to load the new configuration"
if [[ "$OS" == "Darwin" ]]; then
  echo "  2. Run 'darwin-rebuild switch --flake ~/.config/nix-darwin' to apply Nix changes"
else
  echo "  2. Run 'home-manager switch --flake ~/.config/home-manager' to apply Nix changes"
fi
echo "  3. For work profiles, copy zsh/functions.work.local.example to zsh/functions.work.local"

if [[ "$OS" == "Darwin" ]]; then
  echo ""
  echo "NOTE: If you see Homebrew tap trust warnings, you may need to manually trust taps:"
  echo "  brew trust --tap derailed/k9s"
  echo "  brew trust --tap homeport/tap"
  echo "  brew trust --tap vishvavariya/notchy"
fi
