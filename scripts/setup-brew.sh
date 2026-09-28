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

  # `brew trust` records into $HOME/.homebrew/trust.json. But nix-darwin's
  # activation script runs `brew bundle`/`brew cleanup` as root (whose home is
  # /var/root, not this user's), so it can't see the trust recorded above.
  # Copy the record over so root's brew sees the tap as trusted too.
  TRUST_FILE="$HOME/.homebrew/trust.json"
  if [[ -f "$TRUST_FILE" ]]; then
    sudo mkdir -p /var/root/.homebrew
    sudo cp "$TRUST_FILE" /var/root/.homebrew/trust.json
  fi

  # If WhatsApp was already installed by hand (not via Homebrew), brew bundle
  # refuses to overwrite it and darwin-rebuild fails. Force it to take over here,
  # while we're still running interactively and can prompt for a password.
  if [[ -d "/Applications/WhatsApp.app" ]] && ! brew list --cask whatsapp &>/dev/null; then
    echo "  WhatsApp.app exists but isn't managed by Homebrew - reinstalling it via brew..."
    brew install --cask whatsapp --force
  fi
fi
