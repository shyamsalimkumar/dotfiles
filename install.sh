#!/usr/bin/env bash
# Main installation script for Nix-based dotfiles
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Error: Unsupported OS: $OS. This setup supports macOS and Linux (including WSL2)."
  exit 1
fi

echo "==> Installing dotfiles with Nix..."
echo ""

# Step 1: Machine type (and, on work machines, which optional apps to install)
echo "Step 1/6: Machine type..."
"$DOTFILES_DIR/scripts/setup-machine.sh"
echo ""

# Step 2: Prerequisites
echo "Step 2/6: Installing prerequisites..."
if [[ "$OS" == "Darwin" ]]; then
  "$DOTFILES_DIR/scripts/setup-xcode.sh"
  "$DOTFILES_DIR/scripts/setup-brew.sh"
else
  echo "  Nothing to do on Linux/WSL — Nix itself is installed in the next step."
fi
echo ""

# Step 3: Bootstrap Nix and the system configuration
echo "Step 3/6: Installing Nix and building system configuration..."
if [[ "$OS" == "Darwin" ]]; then
  "$DOTFILES_DIR/nix/bootstrap.sh"
else
  "$DOTFILES_DIR/nix/bootstrap-linux.sh"
fi
echo ""

# Step 4: One-time project setup
echo "Step 4/6: Setting up project directories..."
"$DOTFILES_DIR/scripts/setup-projects.sh"
echo ""

# Step 5: AI tools installation
echo "Step 5/6: Installing AI assistant tools..."
"$DOTFILES_DIR/scripts/setup-ai-tools.sh"
echo ""

# Step 6: Post-installation tasks
echo "Step 6/6: Running post-installation tasks..."
"$DOTFILES_DIR/scripts/post-install.sh"
echo ""

echo "==> Installation complete!"
echo ""
echo "Important: Restart your terminal to load the new configuration."
