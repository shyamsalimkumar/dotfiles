#!/usr/bin/env bash
set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==> Installing AI assistant tools..."

# Re-running each tool's own installer is how you update it (they always
# fetch latest) - ask once instead of silently skipping already-installed
# tools forever, or silently re-downloading them on every single run.
update_ai_tools=false
if command -v no-mistakes >/dev/null 2>&1 || command -v treehouse >/dev/null 2>&1 \
  || command -v omp >/dev/null 2>&1 || command -v gnhf >/dev/null 2>&1 \
  || [[ -e "$HOME/.nvm/alias/pi" ]]; then
  read -rp "  Check for updates to already-installed AI tools? [y/N]: " check_updates
  [[ "$check_updates" =~ ^[Yy] ]] && update_ai_tools=true
fi

# Compares an installed vX.Y.Z-style --version against a repo's latest
# GitHub release tag, so "update" only actually reinstalls when there's a
# real newer version - not on every run just because the user opted in.
# `|| true` on both: under `set -euo pipefail`, a grep that finds no match
# (empty/unexpected API response, unexpected --version output) exits
# non-zero and would otherwise silently kill this whole script.
github_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 || true
}

no_mistakes_install=true
if command -v no-mistakes >/dev/null 2>&1; then
  no_mistakes_install=false
  if [[ "$update_ai_tools" == "true" ]]; then
    current="$(no-mistakes --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
    latest="$(github_latest_tag kunchenguid/no-mistakes)"
    if [[ -n "$latest" && "$current" != "$latest" ]]; then
      echo "  no-mistakes: $current -> $latest"
      no_mistakes_install=true
    else
      echo "  ✓ no-mistakes already up to date ($current)"
    fi
  else
    echo "  no-mistakes already installed"
  fi
fi
if [[ "$no_mistakes_install" == "true" ]]; then
  echo "  Installing/updating no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
fi

treehouse_install=true
if command -v treehouse >/dev/null 2>&1; then
  treehouse_install=false
  if [[ "$update_ai_tools" == "true" ]]; then
    current="$(treehouse --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
    latest="$(github_latest_tag kunchenguid/treehouse)"
    if [[ -n "$latest" && "$current" != "$latest" ]]; then
      echo "  treehouse: $current -> $latest"
      treehouse_install=true
    else
      echo "  ✓ treehouse already up to date ($current)"
    fi
  else
    echo "  treehouse already installed"
  fi
fi
if [[ "$treehouse_install" == "true" ]]; then
  echo "  Installing/updating treehouse..."
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

# nvm itself is never installed anywhere else - home.nix's zshrc only sources
# it if already present. Install it here (official installer, matches the
# ~/.nvm/nvm.sh path zshrc expects) so npm actually exists for gnhf/pi below.
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "  Installing nvm..."
  nvm_latest="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d '"' -f4 || true)"
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

# `npm outdated -g <pkg>` exits 0 with no output when a global package is
# already at latest, and exits 1 with a version table when it isn't - a
# real comparison instead of blindly reinstalling every opted-in run.
if command -v npm >/dev/null 2>&1; then
  gnhf_install=true
  if command -v gnhf >/dev/null 2>&1; then
    gnhf_install=false
    if [[ "$update_ai_tools" == "true" ]]; then
      if npm outdated -g gnhf >/dev/null 2>&1; then
        echo "  ✓ gnhf already up to date"
      else
        echo "  gnhf: update available"
        gnhf_install=true
      fi
    else
      echo "  gnhf already installed"
    fi
  fi
  if [[ "$gnhf_install" == "true" ]]; then
    echo "  Installing/updating gnhf..."
    npm install -g gnhf
  fi
else
  echo -e "  ${YELLOW}WARNING: npm not found, skipping gnhf install${NC}"
fi

# pi runs from its own nvm alias ("pi", used by zsh/aliases.personal) so
# changing the default Node can't break it. The alias only moves when pi's
# own engines.node requirement outgrows the Node it points at.
pi_package="@earendil-works/pi-coding-agent"
version_at_least() { [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" == "$2" ]]; }
if command -v npm >/dev/null 2>&1; then
  pi_node_min="$(npm view "$pi_package" engines.node 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  pi_node="$(cat "$NVM_DIR/alias/pi" 2>/dev/null || true)"
  pi_install=true
  if [[ -n "$pi_node" && -x "$NVM_DIR/versions/node/$pi_node/bin/node" ]] \
    && { [[ -z "$pi_node_min" ]] || version_at_least "${pi_node#v}" "$pi_node_min"; }; then
    echo "  pi uses Node $pi_node (needs >=${pi_node_min:-any})"
  else
    echo "  Installing a Node for pi (needs >=${pi_node_min:-any})..."
    set +u
    nvm install --lts >/dev/null
    pi_node="$(nvm version 'lts/*')"
    if [[ -n "$pi_node_min" ]] && ! version_at_least "${pi_node#v}" "$pi_node_min"; then
      nvm install node >/dev/null
      pi_node="$(nvm version node)"
    fi
    nvm alias pi "$pi_node" >/dev/null
    set -u
    echo "  ✓ nvm alias 'pi' -> $pi_node"
  fi

  pi_node_bin="$NVM_DIR/versions/node/$pi_node/bin"
  if [[ -x "$pi_node_bin/pi" ]]; then
    pi_install=false
    if [[ "$update_ai_tools" == "true" ]]; then
      if PATH="$pi_node_bin:$PATH" npm outdated -g "$pi_package" >/dev/null 2>&1; then
        echo "  ✓ pi already up to date"
      else
        echo "  pi: update available"
        pi_install=true
      fi
    else
      echo "  pi already installed"
    fi
  fi
  if [[ "$pi_install" == "true" ]]; then
    echo "  Installing/updating pi ($pi_package) under Node $pi_node..."
    PATH="$pi_node_bin:$PATH" npm install -g "$pi_package"
  fi
else
  echo -e "  ${YELLOW}WARNING: npm not found, skipping pi install${NC}"
fi

# omp.sh/install is fetched from can1357/oh-my-pi on GitHub (found by
# reading the installer script itself), so it gets the same real version
# comparison as no-mistakes/treehouse instead of blindly reinstalling.
omp_install=true
if command -v omp >/dev/null 2>&1; then
  omp_install=false
  if [[ "$update_ai_tools" == "true" ]]; then
    # omp --version prints "omp/X.Y.Z" - no "v" prefix, unlike no-mistakes/
    # treehouse - so strip the "v" from the release tag to compare like for like.
    current="$(omp --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
    latest_tag="$(github_latest_tag can1357/oh-my-pi)"
    latest="${latest_tag#v}"
    if [[ -n "$latest" && "$current" != "$latest" ]]; then
      echo "  omp (Oh My Pi): $current -> $latest"
      omp_install=true
    else
      echo "  ✓ omp (Oh My Pi) already up to date ($current)"
    fi
  else
    echo "  omp (Oh My Pi) already installed"
  fi
fi
if [[ "$omp_install" == "true" ]]; then
  echo "  Installing/updating omp (Oh My Pi)..."
  curl -fsSL https://omp.sh/install | sh
fi

# firstmate isn't a global binary — it's a repo you clone once and launch your
# agent harness inside; it clones the projects you ask it about into its own
# projects/ subdirectory. Keep the one clone under ~/Projects like everything else.
FIRSTMATE_DIR="$HOME/Projects/github.com/kunchenguid/firstmate"
if [[ -d "$FIRSTMATE_DIR" ]]; then
  if [[ "$update_ai_tools" == "true" ]]; then
    echo "  Updating firstmate..."
    git -C "$FIRSTMATE_DIR" pull || true
  else
    echo "  firstmate already cloned at $FIRSTMATE_DIR"
  fi
else
  echo "  Cloning firstmate to $FIRSTMATE_DIR..."
  mkdir -p "$(dirname "$FIRSTMATE_DIR")"
  git clone https://github.com/kunchenguid/firstmate "$FIRSTMATE_DIR"
fi
