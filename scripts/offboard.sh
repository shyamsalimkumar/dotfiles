#!/usr/bin/env bash
# Undo what post-install.sh set up with your personal accounts, e.g. before
# handing back a work laptop. Key files stay on disk; only their GitHub
# registrations and your logged-in sessions are removed.
#
# Two ways to run it:
#   - On the machine you're leaving: removes the keys recorded in
#     ~/.config/dotfiles/registered, then logs this machine out of everything.
#   - On another machine (the old one is already gone): pick the old keys from
#     your GitHub key list, and say no to the "log this machine out" step.

set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REGISTERED_FILE="$HOME/.config/dotfiles/registered"

confirm() {
  local answer
  read -rp "  $1 [y/N]: " answer
  [[ "$answer" =~ ^[Yy] ]]
}

delete_github_key() {
  local kind="$1" id="$2"
  if gh "$kind" delete "$id" --yes </dev/null 2>&1; then
    echo "  ✓ Deleted $kind $id from GitHub"
  else
    echo -e "  ${YELLOW}⚠ Couldn't delete $kind $id - check https://github.com/settings/keys${NC}"
  fi
}

logout_of() {
  local name="$1"
  shift
  command -v "$1" &>/dev/null || return 0
  if "$@" </dev/null &>/dev/null; then
    echo "  ✓ Logged out of $name"
  else
    echo "  - $name: nothing to log out of"
  fi
}

echo "==> Offboarding..."

# ============================================================================
# GitHub SSH and GPG keys - has to happen before logging out of gh below,
# since deleting them needs your GitHub login.
# ============================================================================
echo ""
echo "==> Removing SSH and GPG keys from GitHub..."
if ! command -v gh &>/dev/null; then
  echo -e "  ${YELLOW}⚠ gh CLI not found - delete keys by hand at https://github.com/settings/keys${NC}"
else
  if ! gh auth status &>/dev/null; then
    echo "  Not logged into GitHub - launching 'gh auth login' (opens your browser)..."
    gh auth login --hostname github.com --git-protocol https --scopes admin:public_key,admin:gpg_key --web || true
  else
    gh_scopes="$(gh auth status 2>&1)"
    if ! grep -q "admin:public_key" <<<"$gh_scopes" || ! grep -q "admin:gpg_key" <<<"$gh_scopes"; then
      echo "  Deleting keys needs extra GitHub permissions - launching 'gh auth refresh' (opens your browser)..."
      gh auth refresh --hostname github.com --scopes admin:public_key,admin:gpg_key || true
    fi
  fi

  if ! gh auth status &>/dev/null; then
    echo -e "  ${YELLOW}⚠ Not logged in - delete keys by hand at https://github.com/settings/keys${NC}"
  elif [[ -s "$REGISTERED_FILE" ]]; then
    while IFS='=' read -r kind id; do
      case "$kind" in
        ssh-key | gpg-key) delete_github_key "$kind" "$id" ;;
      esac
    done <"$REGISTERED_FILE"
    rm -f "$REGISTERED_FILE"
  else
    echo "  No record of this machine's keys ($REGISTERED_FILE) - pick them from your GitHub account."
    echo "  Keys added by this dotfiles setup are titled '<hostname> (dotfiles)'."
    for kind in ssh-key gpg-key; do
      echo ""
      gh "$kind" list
      echo ""
      read -rp "  $kind IDs to delete (space-separated, leave empty to skip): " ids
      for id in $ids; do
        delete_github_key "$kind" "$id"
      done
    done
  fi
fi

# ============================================================================
# Log this machine out. Skipped when running on a machine you're keeping.
# ============================================================================
echo ""
if confirm "Log THIS machine out of GitHub, cloud and other accounts? (only on the machine you're leaving)"; then
  echo ""
  echo "==> Logging out..."

  ssh-add -D &>/dev/null && echo "  ✓ Removed SSH keys from the SSH agent" || true

  printf "protocol=https\nhost=github.com\n\n" | git credential reject 2>/dev/null || true
  echo "  ✓ Cleared saved GitHub credentials from git's credential store"

  if command -v gh &>/dev/null; then
    while gh auth status &>/dev/null; do
      gh auth logout --hostname github.com || break
    done
    echo "  ✓ Logged out of GitHub CLI"
  fi

  logout_of "Google Cloud" gcloud auth revoke --all
  logout_of "AWS SSO" aws sso logout
  logout_of "npm" npm logout
  logout_of "Docker" docker logout
  logout_of "1Password CLI" op signout --all
  logout_of "Claude Code" claude auth logout
else
  echo "  Skipping - this machine stays logged in"
fi

# ============================================================================
# Things no command can do for you
# ============================================================================
echo ""
echo "==> Finish these by hand (in a browser, on any machine):"
echo "  [ ] GitHub sessions:     https://github.com/settings/sessions"
echo "  [ ] GitHub apps:         https://github.com/settings/applications"
echo "      (revoking 'GitHub CLI' also logs gh out on your other machines - just 'gh auth login' again)"
echo "  [ ] GitHub tokens:       https://github.com/settings/tokens"
echo "  [ ] GitHub orgs:         https://github.com/settings/organizations (leave the company org if it's still there)"
echo "  [ ] Google devices:      https://myaccount.google.com/device-activity (also covers Chrome sync)"
echo "  [ ] Apple devices:       https://account.apple.com (Devices)"
echo "  [ ] Password manager:    remove the machine from its device list"
echo "  [ ] Chat apps:           WhatsApp / Telegram / Signal - check Linked Devices on your phone"
echo "  [ ] npm / Docker Hub:    delete tokens you created on that machine"
echo "  [ ] AI tools:            sign out other sessions on claude.ai, ChatGPT, etc."
echo "  [ ] Plain-text secrets:  rotate any personal key/password saved in files there (.env, ~/.aws, ~/.npmrc)"
echo ""
echo "==> Offboarding complete!"
