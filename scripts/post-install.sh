#!/usr/bin/env bash
# Post-installation tasks for Nix-based dotfiles
# Run this after: sudo darwin-rebuild switch --flake ~/.config/nix-darwin (macOS)
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
# SSH local configuration
# ============================================================================
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [[ ! -f "$HOME/.ssh/config.local" ]]; then
  echo ""
  echo "==> Creating ~/.ssh/config.local for host-specific settings..."
  cat > "$HOME/.ssh/config.local" <<EOF
# Host-specific SSH settings (hostnames, usernames, key paths) - not tracked in git.
# ~/.ssh/config (tracked, generic aliases only) includes this file.
EOF
  chmod 600 "$HOME/.ssh/config.local"
  echo "  ✓ Created ~/.ssh/config.local"
else
  echo "  ✓ ~/.ssh/config.local already exists"
fi

# ============================================================================
# GitHub SSH key - generate a dedicated key, register it with GitHub via the
# gh CLI, and wire it into config.local. Idempotent: safe to re-run.
# ============================================================================
if command -v gh &>/dev/null; then
  echo ""
  echo "==> GitHub SSH key..."

  if grep -q "^Host github\.com$" "$HOME/.ssh/config.local" 2>/dev/null; then
    echo "  ✓ github.com already configured in ~/.ssh/config.local"
  else
    read -rp "  Configure a GitHub SSH key now? [Y/n]: " configure_github_ssh
    if [[ "$configure_github_ssh" =~ ^[Nn] ]]; then
      echo "  Skipping GitHub SSH key setup"
      configure_github_ssh_do=false
    else
      configure_github_ssh_do=true
      if ! gh auth status &>/dev/null; then
        echo "  Not logged into GitHub - launching 'gh auth login' (opens your browser)..."
        # --git-protocol https (not ssh) on purpose: gh's own "preferred protocol"
        # setting is unrelated to which SSH key actually gets used for git@github.com
        # (that's config.local, set up below) - it just decides whether *gh itself*
        # defaults to HTTPS or SSH remotes. Picking ssh here would make gh ask its
        # own "upload an SSH key?" question too, duplicating the selection below.
        gh auth login --hostname github.com --git-protocol https --scopes admin:public_key --web || true
      fi
      if ! gh auth status &>/dev/null; then
        echo "  ⚠ Still not logged in - skipping GitHub SSH key setup. Run 'gh auth login', then re-run this script"
        configure_github_ssh_do=false
      fi
    fi
  fi

  if [[ "${configure_github_ssh_do:-false}" == "true" ]]; then
    GITHUB_KEY=""
    mapfile -t existing_keys < <(find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" 2>/dev/null | sed 's/\.pub$//')
    if [[ ${#existing_keys[@]} -gt 0 ]]; then
      echo "  Use an existing SSH key for GitHub, or generate a dedicated one?"
      select choice in "${existing_keys[@]}" "Generate a new dedicated key"; do
        if [[ "$REPLY" -ge 1 && "$REPLY" -le ${#existing_keys[@]} ]]; then
          GITHUB_KEY="$choice"
        fi
        break
      done
    fi

    if [[ -z "$GITHUB_KEY" ]]; then
      GITHUB_KEY="$HOME/.ssh/github"
      if [[ ! -f "$GITHUB_KEY" ]]; then
        echo "  Generating a new ed25519 key at $GITHUB_KEY..."
        key_email="$(git config --get user.email 2>/dev/null || echo "$(whoami)@$(hostname -s)")"
        ssh-keygen -t ed25519 -f "$GITHUB_KEY" -N "" -C "$key_email"
      else
        echo "  ✓ $GITHUB_KEY already exists, reusing it"
      fi
    else
      echo "  ✓ Reusing existing key: $GITHUB_KEY"
    fi
    chmod 600 "$GITHUB_KEY"

    if [[ "$OS" == "Darwin" ]]; then
      ssh-add --apple-use-keychain "$GITHUB_KEY" 2>&1 || true
    else
      eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
      ssh-add "$GITHUB_KEY" 2>&1 || true
    fi

    fingerprint="$(ssh-keygen -lf "${GITHUB_KEY}.pub" | awk '{print $2}')"
    if gh ssh-key list 2>/dev/null | grep -q "$fingerprint"; then
      echo "  ✓ Key already registered with GitHub"
    elif gh ssh-key add "${GITHUB_KEY}.pub" --title "$(hostname -s) (dotfiles)" 2>&1; then
      echo "  ✓ Key added to your GitHub account"
    else
      echo "  ⚠ Failed to add key to GitHub - you may need broader auth scope:"
      echo "    gh auth refresh -h github.com -s admin:public_key"
    fi

    {
      echo ""
      echo "Host github.com"
      echo "    HostName github.com"
      echo "    User git"
      echo "    IdentityFile $GITHUB_KEY"
      echo "    IdentitiesOnly yes"
      [[ "$OS" == "Darwin" ]] && echo "    UseKeychain yes"
      echo "    AddKeysToAgent yes"
    } >> "$HOME/.ssh/config.local"
    echo "  ✓ Added github.com entry to ~/.ssh/config.local"
  fi
else
  echo ""
  echo "  ⚠ gh CLI not found, skipping GitHub SSH key setup"
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
# Claude settings.json (real writable file, not a Nix-managed symlink -
# the claude CLI needs to write to it for plugin/marketplace state)
# ============================================================================
mkdir -p "$HOME/.claude"
# Remove a leftover read-only Nix-managed symlink from before this file was
# excluded from home.nix's home.file, if one is still there.
[[ -L "$HOME/.claude/settings.json" ]] && rm "$HOME/.claude/settings.json"
if [[ ! -e "$HOME/.claude/settings.json" ]]; then
  echo ""
  echo "==> Seeding ~/.claude/settings.json..."
  cp "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  echo "  ✓ Created ~/.claude/settings.json"
fi

# ============================================================================
# Claude plugin installation
# ============================================================================
if command -v claude &>/dev/null; then
  echo ""
  echo "==> Installing Claude plugins..."

  # None of these marketplaces - including the official one - are registered
  # by default on a fresh install. Register whichever are missing before the
  # install loop below tries to resolve plugins from them.
  if ! claude plugin marketplace list 2>/dev/null | grep -q "claude-plugins-official"; then
    claude plugin marketplace add anthropics/claude-plugins-official 2>&1 || true
  fi
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
  echo "  2. Run 'sudo darwin-rebuild switch --flake ~/.config/nix-darwin' to apply Nix changes"
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
