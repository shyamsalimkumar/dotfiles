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

  # Homebrew now warns that HOMEBREW_NO_REQUIRE_TAP_TRUST is deprecated in
  # favor of the brew trust call above - that fix was tried (see git log)
  # and the untrusted-tap error came straight back during darwin-rebuild's
  # root-context brew cleanup, so the underlying root-context trust-store
  # lookup this env var works around is NOT actually fixed upstream yet.
  # Deprecated-but-working beats warning-free-but-broken - restored.
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
  # --verbose shows the installed and new versions, so the prompt below has
  # everything up front and brew's own confirmation can be skipped with --yes.
  outdated="$(brew outdated --greedy --verbose 2>/dev/null || true)"
  if [[ -n "$outdated" ]]; then
    echo ""
    echo "  Updates available:"
    echo "$outdated" | sed 's/^/    /'
    read -rp "  Install these updates now? [y/N]: " update_outdated
    if [[ "$update_outdated" =~ ^[Yy] ]]; then
      brew upgrade --greedy --yes || true
    fi
  fi
fi
