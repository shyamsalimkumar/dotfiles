#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"

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
  # Homebrew refuses to install casks from third-party taps until they're
  # explicitly trusted. Darwin.nix's homebrew.taps installs vishvavariya/notchy,
  # so trust it here before nix-darwin's activation tries to install its cask.
  brew tap vishvavariya/notchy
  brew trust --taps vishvavariya/notchy

  # HOMEBREW_NO_REQUIRE_TAP_TRUST (previously written here) is now deprecated
  # by Homebrew itself in favor of the brew trust call above - strip it from
  # any machine that already has it from an earlier run of this script.
  if [[ -f /etc/homebrew/brew.env ]] && grep -q "^HOMEBREW_NO_REQUIRE_TAP_TRUST=" /etc/homebrew/brew.env; then
    sudo sed -i '' '/^HOMEBREW_NO_REQUIRE_TAP_TRUST=/d' /etc/homebrew/brew.env
  fi

  # If WhatsApp was already installed by hand (not via Homebrew), brew bundle
  # refuses to overwrite it and darwin-rebuild fails. Force it to take over here,
  # while we're still running interactively and can prompt for a password.
  if [[ -d "/Applications/WhatsApp.app" ]] && ! brew list --cask whatsapp &>/dev/null; then
    echo "  WhatsApp.app exists but isn't managed by Homebrew - reinstalling it via brew..."
    brew install --cask whatsapp --force
  fi

  # Check for updates to every Homebrew-managed app/tool (casks and
  # formulae). --greedy also checks self-updating casks (Zoom, etc), which
  # brew skips by default on the assumption the app updates itself silently.
  outdated="$(brew outdated --greedy 2>/dev/null || true)"
  if [[ -n "$outdated" ]]; then
    echo ""
    echo "  Updates available:"
    echo "$outdated" | sed 's/^/    /'
    read -rp "  Install these updates now? [y/N]: " update_outdated
    if [[ "$update_outdated" =~ ^[Yy] ]]; then
      brew upgrade --greedy || true
    fi
  fi
fi
