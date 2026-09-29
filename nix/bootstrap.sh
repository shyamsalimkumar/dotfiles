#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting NixOS Darwin bootstrap...${NC}"

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo -e "${YELLOW}Nix not found. Installing Determinate Nix...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
else
    echo -e "${GREEN}Nix already installed.${NC}"
fi

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create/refresh symlink to dotfiles nix directory in ~/.config. ln -sfn
# unconditionally keeps this current even if the dotfiles checkout has moved
# since the symlink was first created - a plain existence check would leave
# it silently pointing at the old, now-wrong location.
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p ~/.config
if [ ! -L ~/.config/nix-darwin ] || [ "$(readlink ~/.config/nix-darwin)" != "$SCRIPT_DIR" ]; then
    ln -sfn "$SCRIPT_DIR" ~/.config/nix-darwin
    echo -e "${GREEN}Linked: ~/.config/nix-darwin -> $SCRIPT_DIR${NC}"
fi

# Run first build
echo -e "${YELLOW}Running first darwin-rebuild...${NC}"
# --impure lets darwin.nix and work-profiles.nix read per-machine files outside
# the flake (~/.config/dotfiles, local.nix) - pure evaluation treats them as missing.
sudo nix run nix-darwin -- switch --impure --flake "$SCRIPT_DIR#mac"

echo -e "${GREEN}Bootstrap complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: $DOTFILES_DIR/scripts/post-install.sh"
echo "  2. Restart your terminal to load the new configuration"
