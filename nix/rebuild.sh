#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Rebuilding Darwin configuration...${NC}"

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Rebuild
# --impure lets darwin.nix and work-profiles.nix read per-machine files outside
# the flake (~/.config/dotfiles, local.nix) - pure evaluation treats them as missing.
sudo darwin-rebuild switch --impure --flake "$SCRIPT_DIR#mac"

echo -e "${GREEN}Rebuild complete!${NC}"
