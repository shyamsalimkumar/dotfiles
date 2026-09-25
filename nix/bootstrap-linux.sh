#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting home-manager bootstrap for Linux/WSL...${NC}"

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
mkdir -p ~/.config
if [ ! -L ~/.config/home-manager ]; then
    ln -sf "$SCRIPT_DIR" ~/.config/home-manager
    echo -e "${GREEN}Created symlink: ~/.config/home-manager -> $SCRIPT_DIR${NC}"
fi

# Run first build
echo -e "${YELLOW}Running first home-manager switch...${NC}"
nix run home-manager -- switch --flake "$SCRIPT_DIR#linux"

echo -e "${GREEN}Bootstrap complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  Restart your shell (or open a new WSL/terminal window) to load the new configuration"
