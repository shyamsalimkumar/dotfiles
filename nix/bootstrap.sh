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

# Create symlink to dotfiles nix directory in ~/.config
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p ~/.config
if [ ! -L ~/.config/nix-darwin ]; then
    ln -sf "$SCRIPT_DIR" ~/.config/nix-darwin
    echo -e "${GREEN}Created symlink: ~/.config/nix-darwin -> $SCRIPT_DIR${NC}"
fi

# Run first build
echo -e "${YELLOW}Running first darwin-rebuild...${NC}"
nix run nix-darwin -- switch --flake "$SCRIPT_DIR#mac"

echo -e "${GREEN}Bootstrap complete!${NC}"
echo -e "${YELLOW}Please restart your terminal or run: source ~/.zshrc${NC}"
