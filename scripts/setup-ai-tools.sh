#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing AI assistant tools..."

if command -v no-mistakes >/dev/null 2>&1; then
  echo "  no-mistakes already installed"
else
  echo "  Installing no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
fi

if command -v treehouse >/dev/null 2>&1; then
  echo "  treehouse already installed"
else
  echo "  Installing treehouse..."
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

# nvm itself is never installed anywhere else - home.nix's zshrc only sources
# it if already present. Install it here (official installer, matches the
# ~/.nvm/nvm.sh path zshrc expects) so npm actually exists for gnhf/pi below.
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "  Installing nvm..."
  nvm_latest="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d '"' -f4)"
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_latest}/install.sh" | bash
fi
# nvm's script and shell functions aren't written to be safe under `set -u` -
# relax it for sourcing and for any nvm calls below.
set +u
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v npm >/dev/null 2>&1; then
  echo "  npm already available"
elif command -v nvm >/dev/null 2>&1; then
  echo "  Installing latest LTS Node via nvm..."
  nvm install --lts
  nvm alias default 'lts/*'
fi
set -u

if command -v npm >/dev/null 2>&1; then
  if command -v gnhf >/dev/null 2>&1; then
    echo "  gnhf already installed"
  else
    echo "  Installing gnhf..."
    npm install -g gnhf
  fi

  if command -v pi >/dev/null 2>&1; then
    echo "  pi already installed"
  else
    echo "  Installing pi (@earendil-works/pi-coding-agent)..."
    npm install -g @earendil-works/pi-coding-agent
  fi
else
  echo "  WARNING: npm not found, skipping gnhf and pi install"
fi

if command -v omp >/dev/null 2>&1; then
  echo "  omp (Oh My Pi) already installed"
else
  echo "  Installing omp (Oh My Pi)..."
  curl -fsSL https://omp.sh/install | sh
fi

# firstmate isn't a global binary — it's a repo you clone once and launch your
# agent harness inside; it clones the projects you ask it about into its own
# projects/ subdirectory. Keep the one clone under ~/Projects like everything else.
FIRSTMATE_DIR="$HOME/Projects/github.com/kunchenguid/firstmate"
if [[ -d "$FIRSTMATE_DIR" ]]; then
  echo "  firstmate already cloned at $FIRSTMATE_DIR"
else
  echo "  Cloning firstmate to $FIRSTMATE_DIR..."
  mkdir -p "$(dirname "$FIRSTMATE_DIR")"
  git clone https://github.com/kunchenguid/firstmate "$FIRSTMATE_DIR"
fi
