#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Rebuilding home-manager configuration...${NC}"

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Rebuild
home-manager switch --flake "$SCRIPT_DIR#linux"

echo -e "${GREEN}Rebuild complete!${NC}"
