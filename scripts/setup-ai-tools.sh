#!/usr/bin/env bash
set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# shellcheck source=scripts/lib/pick-list.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/pick-list.sh"

echo "==> Installing AI assistant tools..."

# Re-running each tool's own installer is how you update it (they always
# fetch latest). Missing tools get installed; installed ones are checked
# first, and only the updates picked from the list below get reinstalled.
update_labels=()
update_flags=()
offer_update() {
  echo "  $1"
  update_labels+=("$1")
  update_flags+=("$2")
}

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
  current="$(no-mistakes --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  latest="$(github_latest_tag kunchenguid/no-mistakes)"
  if [[ -n "$latest" && "$current" != "$latest" ]]; then
    offer_update "no-mistakes: $current -> $latest" no_mistakes_install
  else
    echo "  ✓ no-mistakes already up to date ($current)"
  fi
fi

treehouse_install=true
if command -v treehouse >/dev/null 2>&1; then
  treehouse_install=false
  current="$(treehouse --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  latest="$(github_latest_tag kunchenguid/treehouse)"
  if [[ -n "$latest" && "$current" != "$latest" ]]; then
    offer_update "treehouse: $current -> $latest" treehouse_install
  else
    echo "  ✓ treehouse already up to date ($current)"
  fi
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
gnhf_install=false
if command -v npm >/dev/null 2>&1; then
  if ! command -v gnhf >/dev/null 2>&1; then
    gnhf_install=true
  elif npm outdated -g gnhf >/dev/null 2>&1; then
    echo "  ✓ gnhf already up to date"
  else
    offer_update "gnhf: update available" gnhf_install
  fi
else
  echo -e "  ${YELLOW}WARNING: npm not found, skipping gnhf install${NC}"
fi

# pi runs from its own nvm alias ("pi", used by zsh/aliases.personal) so
# changing the default Node can't break it. The alias only moves when pi's
# own engines.node requirement outgrows the Node it points at.
pi_package="@earendil-works/pi-coding-agent"
version_at_least() { [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" == "$2" ]]; }
pi_install=false
if command -v npm >/dev/null 2>&1; then
  pi_node_min="$(npm view "$pi_package" engines.node 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  pi_node="$(cat "$NVM_DIR/alias/pi" 2>/dev/null || true)"
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
  if [[ ! -x "$pi_node_bin/pi" ]]; then
    pi_install=true
  elif PATH="$pi_node_bin:$PATH" npm outdated -g "$pi_package" >/dev/null 2>&1; then
    echo "  ✓ pi already up to date"
  else
    offer_update "pi: update available" pi_install
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
  # omp --version prints "omp/X.Y.Z" - no "v" prefix, unlike no-mistakes/
  # treehouse - so strip the "v" from the release tag to compare like for like.
  current="$(omp --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  latest_tag="$(github_latest_tag can1357/oh-my-pi)"
  latest="${latest_tag#v}"
  if [[ -n "$latest" && "$current" != "$latest" ]]; then
    offer_update "omp (Oh My Pi): $current -> $latest" omp_install
  else
    echo "  ✓ omp (Oh My Pi) already up to date ($current)"
  fi
fi

# firstmate isn't a global binary — it's a repo you clone once and launch your
# agent harness inside; it clones the projects you ask it about into its own
# projects/ subdirectory. Keep the one clone under ~/Projects like everything else.
FIRSTMATE_DIR="$HOME/Projects/github.com/kunchenguid/firstmate"
firstmate_clone=false
firstmate_update=false
if [[ ! -d "$FIRSTMATE_DIR" ]]; then
  firstmate_clone=true
else
  git -C "$FIRSTMATE_DIR" fetch -q || true
  behind="$(git -C "$FIRSTMATE_DIR" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)"
  if [[ "$behind" -gt 0 ]]; then
    offer_update "firstmate: $behind new commits" firstmate_update
  else
    echo "  ✓ firstmate already up to date"
  fi
fi

if [[ ${#update_labels[@]} -gt 0 ]]; then
  echo ""
  echo "  AI tool updates available:"
  pick_from_list "${update_labels[@]}"
  for i in ${PICKED[@]+"${PICKED[@]}"}; do printf -v "${update_flags[$i]}" true; done
fi

if [[ "$no_mistakes_install" == "true" ]]; then
  echo "  Installing/updating no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
fi
if [[ "$treehouse_install" == "true" ]]; then
  echo "  Installing/updating treehouse..."
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi
if [[ "$gnhf_install" == "true" ]]; then
  echo "  Installing/updating gnhf..."
  npm install -g gnhf
fi
if [[ "$pi_install" == "true" ]]; then
  echo "  Installing/updating pi ($pi_package) under Node $pi_node..."
  PATH="$pi_node_bin:$PATH" npm install -g "$pi_package"
fi
if [[ "$omp_install" == "true" ]]; then
  echo "  Installing/updating omp (Oh My Pi)..."
  curl -fsSL https://omp.sh/install | sh
fi
if [[ "$firstmate_clone" == "true" ]]; then
  echo "  Cloning firstmate to $FIRSTMATE_DIR..."
  mkdir -p "$(dirname "$FIRSTMATE_DIR")"
  git clone https://github.com/kunchenguid/firstmate "$FIRSTMATE_DIR"
fi
if [[ "$firstmate_update" == "true" ]]; then
  echo "  Updating firstmate..."
  git -C "$FIRSTMATE_DIR" pull || true
fi
