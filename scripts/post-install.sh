#!/usr/bin/env bash
# Post-installation tasks for Nix-based dotfiles
# Run this after: sudo darwin-rebuild switch --flake ~/.config/nix-darwin#mac (macOS)
# or: home-manager switch --flake ~/.config/home-manager#linux (Linux/WSL)

set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
# AWS CLI configuration - region/output default only. Credentials are left
# empty on purpose (no real access keys or SSO details can be guessed here),
# and gcloud gets nothing: it self-initializes its own config on first use
# (gcloud init/gcloud auth login), so there's no static file worth seeding.
# ============================================================================
mkdir -p "$HOME/.aws"
chmod 700 "$HOME/.aws"
if [[ ! -f "$HOME/.aws/config" ]]; then
  echo ""
  echo "==> Creating ~/.aws/config..."
  cat > "$HOME/.aws/config" <<EOF
[default]
region = eu-west-1
output = json
EOF
  chmod 600 "$HOME/.aws/config"
  echo "  ✓ Created ~/.aws/config"
else
  echo "  ✓ ~/.aws/config already exists"
fi

if [[ ! -f "$HOME/.aws/credentials" ]]; then
  echo ""
  echo "==> Creating ~/.aws/credentials..."
  cat > "$HOME/.aws/credentials" <<EOF
# Not tracked in git. Add a profile here, e.g.:
# [default]
# aws_access_key_id = ...
# aws_secret_access_key = ...
# Or use AWS SSO instead: run 'aws configure sso' to populate this file.
EOF
  chmod 600 "$HOME/.aws/credentials"
  echo "  ✓ Created ~/.aws/credentials"
else
  echo "  ✓ ~/.aws/credentials already exists"
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
        echo -e "  ${YELLOW}⚠ Still not logged in - skipping GitHub SSH key setup. Run 'gh auth login', then re-run this script${NC}"
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
      # --apple-use-keychain only exists on Apple's ssh-add. If openssh
      # (nix/home.nix) is ahead of /usr/bin on PATH, `ssh-add` resolves to
      # the vanilla OpenSSH build instead, which rejects that flag - fall
      # back to a plain ssh-add so the key still gets loaded either way.
      ssh-add --apple-use-keychain "$GITHUB_KEY" 2>&1 || ssh-add "$GITHUB_KEY" 2>&1 || true
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
      echo -e "  ${YELLOW}⚠ Failed to add key to GitHub - you may need broader auth scope:${NC}"
      echo "    gh auth refresh -h github.com -s admin:public_key"
    fi

    {
      echo ""
      echo "Host github.com"
      echo "    HostName github.com"
      echo "    User git"
      echo "    IdentityFile $GITHUB_KEY"
      echo "    IdentitiesOnly yes"
      echo "    AddKeysToAgent yes"
    } >> "$HOME/.ssh/config.local"
    echo "  ✓ Added github.com entry to ~/.ssh/config.local"
  fi

  # ==========================================================================
  # GitHub GPG key - generate a commit-signing key, register it with GitHub
  # via gh, and wire it into config.local. commit.gpgsign itself stays
  # per-machine (here, not in the tracked Nix config) so a machine that
  # skips this doesn't have every commit start failing to sign.
  # ==========================================================================
  # A key can be configured locally (signingkey set) but not actually
  # registered with GitHub yet - e.g. gh was already logged in from the SSH
  # step above without the admin:gpg_key scope, so registration failed there.
  # Only treat this as "done" once the key is confirmed on GitHub's side too;
  # otherwise retry registration alone, without re-prompting or regenerating.
  local_signingkey="$(git config --file "$HOME/.gitconfig.local" --get user.signingkey 2>/dev/null || true)"
  gpg_confirmed_on_github=false
  if [[ -n "$local_signingkey" ]]; then
    if ! command -v gh &>/dev/null || ! gh auth status &>/dev/null; then
      gpg_confirmed_on_github=true # can't check right now - trust local config
    elif gh gpg-key list 2>/dev/null | grep -q "$local_signingkey"; then
      gpg_confirmed_on_github=true
    fi
  fi

  if [[ "$gpg_confirmed_on_github" == "true" ]]; then
    echo "  ✓ GPG signing already configured in ~/.gitconfig.local"
  elif [[ -n "$local_signingkey" ]]; then
    echo -e "  ${YELLOW}⚠ Key $local_signingkey is set locally but wasn't found on GitHub - retrying registration${NC}"
    if ! gh auth status &>/dev/null; then
      gh auth login --hostname github.com --git-protocol https --scopes admin:gpg_key --web || true
    fi
    gpg_key_file="$(mktemp)"
    gpg --armor --export "$local_signingkey" > "$gpg_key_file"
    if gh gpg-key add "$gpg_key_file" --title "$(hostname -s) (dotfiles)" 2>&1; then
      echo "  ✓ Key added to your GitHub account"
    else
      echo -e "  ${YELLOW}⚠ Failed to add key to GitHub - you may need broader auth scope:${NC}"
      echo "    gh auth refresh -h github.com -s admin:gpg_key"
    fi
    rm -f "$gpg_key_file"
  else
    read -rp "  Configure GPG commit signing now? [Y/n]: " configure_gpg
    if [[ "$configure_gpg" =~ ^[Nn] ]]; then
      echo "  Skipping GPG key setup"
    else
      if ! gh auth status &>/dev/null; then
        echo "  Not logged into GitHub - launching 'gh auth login' (opens your browser)..."
        gh auth login --hostname github.com --git-protocol https --scopes admin:gpg_key --web || true
      fi

      if ! gh auth status &>/dev/null; then
        echo -e "  ${YELLOW}⚠ Still not logged in - skipping GPG key setup. Run 'gh auth login', then re-run this script${NC}"
      else
        git_email="$(git config --get user.email 2>/dev/null || true)"
        git_name="$(git config --get user.name 2>/dev/null || echo "$(whoami)")"

        mapfile -t existing_gpg_keys < <(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec/ {print $5}')
        GPG_KEY_ID=""
        if [[ ${#existing_gpg_keys[@]} -gt 0 ]]; then
          echo "  Use an existing GPG key for signing, or generate a dedicated one?"
          select choice in "${existing_gpg_keys[@]}" "Generate a new dedicated key"; do
            if [[ "$REPLY" -ge 1 && "$REPLY" -le ${#existing_gpg_keys[@]} ]]; then
              GPG_KEY_ID="$choice"
            fi
            break
          done
        fi

        if [[ -z "$GPG_KEY_ID" ]]; then
          if [[ -z "$git_email" ]]; then
            echo -e "  ${YELLOW}⚠ No git user.email set - skipping GPG key generation${NC}"
          else
            echo "  Generating a new ed25519 signing key for $git_name <$git_email>..."
            gpg --batch --passphrase '' --quick-generate-key "$git_name <$git_email>" ed25519 sign 0
            GPG_KEY_ID="$(gpg --list-secret-keys --with-colons "$git_email" 2>/dev/null | awk -F: '/^sec/ {print $5; exit}')"
          fi
        else
          echo "  ✓ Reusing existing GPG key: $GPG_KEY_ID"
        fi

        if [[ -n "$GPG_KEY_ID" ]]; then
          if gh gpg-key list 2>/dev/null | grep -q "$GPG_KEY_ID"; then
            echo "  ✓ Key already registered with GitHub"
          else
            gpg_key_file="$(mktemp)"
            gpg --armor --export "$GPG_KEY_ID" > "$gpg_key_file"
            if gh gpg-key add "$gpg_key_file" --title "$(hostname -s) (dotfiles)" 2>&1; then
              echo "  ✓ Key added to your GitHub account"
            else
              echo -e "  ${YELLOW}⚠ Failed to add key to GitHub - you may need broader auth scope:${NC}"
              echo "    gh auth refresh -h github.com -s admin:gpg_key"
            fi
            rm -f "$gpg_key_file"
          fi

          {
            echo "	signingkey = $GPG_KEY_ID"
          } >> "$HOME/.gitconfig.local"
          {
            echo ""
            echo "[commit]"
            echo "	gpgsign = true"
          } >> "$HOME/.gitconfig.local"
          echo "  ✓ Added signingkey and commit.gpgsign to ~/.gitconfig.local"
        fi
      fi
    fi
  fi
else
  echo ""
  echo -e "  ${YELLOW}⚠ gh CLI not found, skipping GitHub SSH key and GPG key setup${NC}"
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
    echo -e "  ${YELLOW}⚠ Neovim plugin sync had warnings (this is often normal)${NC}"
  fi
else
  echo ""
  echo -e "  ${YELLOW}⚠ Neovim not found, skipping plugin sync${NC}"
fi

# ============================================================================
# VS Code extensions
# ============================================================================
if command -v code &>/dev/null; then
  echo ""
  echo "==> Installing VS Code extensions..."
  installed_extensions="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue
    if grep -qix "$extension" <<< "$installed_extensions"; then
      echo "  ✓ Already installed: $extension"
    else
      echo "  Installing: $extension"
      code --install-extension "$extension" 2>&1 || echo -e "  ${YELLOW}⚠ Failed to install $extension${NC}"
    fi
  done < "$DOTFILES_DIR/vscode/extensions.txt"
else
  echo ""
  echo -e "  ${YELLOW}⚠ VS Code 'code' command not found, skipping extension install${NC}"
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
    echo -e "  ${YELLOW}⚠ No plugins defined in claude/settings.json${NC}"
  else
    installed_json="$HOME/.claude/plugins/installed_plugins.json"

    while IFS= read -r plugin; do
      if [[ -f "$installed_json" ]] && jq -e --arg p "$plugin" '.plugins[$p]' "$installed_json" &>/dev/null; then
        echo "  ✓ Already installed: $plugin"
        continue
      fi
      echo "  Installing plugin: $plugin"
      if ! claude plugin install "$plugin" --yes 2>&1; then
        echo -e "  ${YELLOW}⚠ Failed to install $plugin${NC}"
      fi
    done <<< "$plugins"
  fi
else
  echo ""
  echo -e "  ${YELLOW}⚠ Claude CLI not found, skipping plugin installation${NC}"
  echo "    Install claude-code first, then re-run this script"
fi

# ============================================================================
# Claude skills - reconcile skills installed via `npx skills add ... -g` (see
# README "Manual step") into claude/skills/. That installer isn't reliably
# leaving the symlink in place, so treat ~/.agents/skills as the source of
# truth and self-heal here on every run. claude/skills/ is Nix-managed as a
# single directory symlink (see nix/home.nix), so linking happens inside the
# repo itself, not directly under ~/.claude/skills. Skills already provided
# by a Claude Code plugin (mattpocock-skills, andrej-karpathy-skills) are
# skipped - claude/skills/ is a tracked working tree, and duplicating a
# plugin skill there both fights the plugin and risks clobbering a tracked
# file if the name collides.
# ============================================================================
plugin_skill_names="$(find "$HOME/.claude/plugins/marketplaces"/*/skills -iname "SKILL.md" 2>/dev/null \
  | xargs -n1 dirname 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u)"

claude_agents_skills_dir="$HOME/.agents/skills"
if [[ -d "$claude_agents_skills_dir" ]]; then
  echo ""
  echo "==> Linking global skills for Claude..."
  for skill_src in "$claude_agents_skills_dir"/*/; do
    name="$(basename "$skill_src")"
    # no-mistakes is dropped directly by its own installer (see
    # scripts/setup-ai-tools.sh), not by `npx skills add` - leave it alone
    # even though a same-named copy also happens to exist here.
    [[ "$name" == "no-mistakes" ]] && continue
    grep -qxF "$name" <<< "$plugin_skill_names" && continue
    target="$DOTFILES_DIR/claude/skills/$name"
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "  Backing up existing $target → ${target}.bak"
      mv "$target" "${target}.bak"
    fi
    ln -sfn "$skill_src" "$target"
    echo "  ✓ Linked global skill for Claude: $name"
    ignore_line="claude/skills/$name"
    grep -qxF "$ignore_line" "$DOTFILES_DIR/.gitignore" || echo "$ignore_line" >> "$DOTFILES_DIR/.gitignore"
  done
fi

# ============================================================================
# Pi skills
# ============================================================================
# Pi (npm-globals.txt) has no plugin/marketplace system like Claude Code
# does, so skills installed via `npx skills add ... -g` (see README "Manual
# step") need to be mirrored into its skills directory directly. Treats
# ~/.agents/skills as the source of truth and self-heals here on every run,
# same as the Claude skill reconciliation above.
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
  echo "  2. Run 'sudo darwin-rebuild switch --flake ~/.config/nix-darwin#mac' to apply Nix changes"
else
  echo "  2. Run 'home-manager switch --flake ~/.config/home-manager#linux' to apply Nix changes"
fi
echo "  3. For work profiles, copy zsh/functions.work.local.example to zsh/functions.work.local"

if [[ "$OS" == "Darwin" ]]; then
  echo ""
  echo -e "${YELLOW}NOTE: If you see Homebrew tap trust warnings, you may need to manually trust taps:${NC}"
  echo -e "${YELLOW}  brew trust --tap derailed/k9s${NC}"
  echo -e "${YELLOW}  brew trust --tap homeport/tap${NC}"
  echo -e "${YELLOW}  brew trust --tap vishvavariya/notchy${NC}"

  # Xcode has no cask and can't be installed via Nix - Apple only distributes
  # it via the App Store / developer.apple.com and doesn't allow third-party
  # redistribution. Silent if already present; only warn when it's missing.
  if [[ ! -d "/Applications/Xcode.app" ]]; then
    echo ""
    echo -e "${YELLOW}NOTE: Xcode is not installed. Nix/Homebrew can't install it for you -${NC}"
    echo -e "${YELLOW}  install it yourself from the App Store, or download it from${NC}"
    echo -e "${YELLOW}  https://developer.apple.com/download/all/?q=Xcode${NC}"
  fi

  # This script already offers to check/update every Homebrew app on every
  # run (see scripts/setup-brew.sh) - this is just a manual reference for
  # updating a single self-updating app (Zoom, etc.) without going through
  # that whole prompt, or checking outside of a full install.sh run.
  echo ""
  echo -e "${YELLOW}TIP: Some apps (Zoom, and other Homebrew casks) auto-update in the${NC}"
  echo -e "${YELLOW}  background, so a plain 'brew outdated' won't show them as behind.${NC}"
  echo -e "${YELLOW}  Force-check/update one manually with:${NC}"
  echo -e "${YELLOW}    brew upgrade --cask --greedy zoom${NC}"
  echo -e "${YELLOW}  Or check/update everything Homebrew manages at once:${NC}"
  echo -e "${YELLOW}    brew outdated --greedy${NC}"
  echo -e "${YELLOW}    brew upgrade --greedy${NC}"
fi
