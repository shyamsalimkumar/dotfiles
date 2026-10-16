#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"

# shellcheck source=scripts/pick-list.sh
source "$(dirname "${BASH_SOURCE[0]}")/pick-list.sh"

if [[ "$OS" == "Linux" ]] && command -v apt-get &>/dev/null; then
  echo "==> Installing Homebrew prerequisites..."
  sudo apt-get update -qq
  sudo apt-get install -y build-essential procps curl file git
fi

if command -v brew &>/dev/null; then
  echo "Homebrew already installed."
else
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo "Homebrew ready: $(brew --version)"

if [[ "$OS" == "Darwin" ]]; then
  # Homebrew refuses to install from third-party taps until they're
  # explicitly trusted, and a per-user `brew trust` didn't reach
  # darwin-rebuild's root-context brew cleanup (tried, see git log). The
  # HOMEBREW_NO_REQUIRE_TAP_TRUST env var is deprecated but still works, and
  # deprecated-but-working beats warning-free-but-broken.
  sudo mkdir -p /etc/homebrew
  if ! grep -q "^HOMEBREW_NO_REQUIRE_TAP_TRUST=" /etc/homebrew/brew.env 2>/dev/null; then
    echo "HOMEBREW_NO_REQUIRE_TAP_TRUST=1" | sudo tee -a /etc/homebrew/brew.env >/dev/null
  fi

  # If WhatsApp was already installed by hand (not via Homebrew), brew bundle
  # refuses to overwrite it and darwin-rebuild fails. Force it to take over here,
  # while we're still running interactively and can prompt for a password.
  if [[ -d "/Applications/WhatsApp.app" ]] && ! brew list --cask whatsapp &>/dev/null; then
    echo "  WhatsApp.app exists but isn't managed by Homebrew - reinstalling it via brew..."
    brew install --cask whatsapp --force --yes
  fi

  # Check for updates to every Homebrew-managed app/tool (casks and
  # formulae). --greedy also checks self-updating casks (Slack, etc), which
  # brew skips by default on the assumption the app updates itself silently.
  # --verbose shows the installed and new versions, so the pick-list below has
  # everything up front and brew's own confirmation can be skipped with --yes.
  outdated="$(brew outdated --greedy --verbose 2>/dev/null || true)"
  if [[ -n "$outdated" ]]; then
    echo ""
    echo "  Updates available:"
    lines=()
    while IFS= read -r line; do lines+=("$line"); done <<< "$outdated"
    pick_from_list "${lines[@]}"
    names=()
    for i in ${PICKED[@]+"${PICKED[@]}"}; do names+=("${lines[$i]%% *}"); done
    if [[ ${#names[@]} -gt 0 ]]; then
      brew upgrade --greedy --yes "${names[@]}" || true
    fi
  fi
fi
