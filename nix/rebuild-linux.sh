#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Rebuilding home-manager configuration...${NC}"

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=nix/pick-branch.sh
source "$SCRIPT_DIR/pick-branch.sh"
pick_branch "$SCRIPT_DIR"

# Rebuild
home-manager switch -b backup --flake "$SCRIPT_DIR#linux"

echo -e "${GREEN}Rebuild complete!${NC}"
