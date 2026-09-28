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
# Activation runs brew as root, which can't see the tap trust recorded under this
# user's home (see scripts/setup-brew.sh) - skip that check for this run instead.
sudo HOMEBREW_NO_REQUIRE_TAP_TRUST=1 darwin-rebuild switch --flake "$SCRIPT_DIR#mac"

echo -e "${GREEN}Rebuild complete!${NC}"
