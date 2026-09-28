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

  # nix-darwin's activation runs brew as root, and that root context does not
  # reliably inherit HOMEBREW_NO_REQUIRE_TAP_TRUST passed via `sudo VAR=1 cmd`
  # (nix-darwin's own internal re-exec appears to strip it). /etc/homebrew/brew.env
  # is read directly off disk by brew's launcher on every invocation regardless
  # of caller environment, so persist the setting there instead.
  sudo mkdir -p /etc/homebrew
  if ! grep -q "^HOMEBREW_NO_REQUIRE_TAP_TRUST=" /etc/homebrew/brew.env 2>/dev/null; then
    echo "HOMEBREW_NO_REQUIRE_TAP_TRUST=1" | sudo tee -a /etc/homebrew/brew.env >/dev/null
  fi

  # If WhatsApp was already installed by hand (not via Homebrew), brew bundle
  # refuses to overwrite it and darwin-rebuild fails. Force it to take over here,
  # while we're still running interactively and can prompt for a password.
  if [[ -d "/Applications/WhatsApp.app" ]] && ! brew list --cask whatsapp &>/dev/null; then
    echo "  WhatsApp.app exists but isn't managed by Homebrew - reinstalling it via brew..."
    brew install --cask whatsapp --force
  fi

  # Check for AI tool cask updates (claude-code, claude desktop app, etc).
  # --greedy is needed because these are auto_updates casks, which brew
  # skips by default on the assumption the app updates itself silently.
  outdated_ai_casks="$(brew outdated --cask --greedy 2>/dev/null | grep -i claude || true)"
  if [[ -n "$outdated_ai_casks" ]]; then
    echo ""
    echo "  Updates available:"
    echo "$outdated_ai_casks" | sed 's/^/    /'
    read -rp "  Install these updates now? [y/N]: " update_ai_casks
    if [[ "$update_ai_casks" =~ ^[Yy] ]]; then
      # shellcheck disable=SC2046
      brew upgrade --cask --greedy $(echo "$outdated_ai_casks" | awk '{print $1}') || true
    fi
  fi
fi
