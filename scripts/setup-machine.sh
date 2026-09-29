#!/usr/bin/env bash
# Asks once whether this is a personal or work machine, and on a work machine
# which optional Mac apps (nix/optional-casks.txt) to install. Runs first in
# install.sh, before anything gets installed. Answers are saved in
# ~/.config/dotfiles and read by nix/darwin.nix and scripts/post-install.sh.
#
# Runs before Nix exists, so it must stay compatible with macOS's bash 3.2
# (no mapfile, no associative arrays).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$HOME/.config/dotfiles"
MACHINE_TYPE_FILE="$STATE_DIR/machine"
OPTIONAL_CASKS_FILE="$STATE_DIR/optional-casks"
mkdir -p "$STATE_DIR"

if [[ -f "$MACHINE_TYPE_FILE" ]]; then
  machine_type="$(cat "$MACHINE_TYPE_FILE")"
  echo "  ✓ Machine type: $machine_type (delete $MACHINE_TYPE_FILE to change it)"
else
  echo "==> Is this a personal or work machine?"
  select machine_type in personal work; do
    [[ -n "$machine_type" ]] && break
  done
  echo "$machine_type" > "$MACHINE_TYPE_FILE"
  echo "  ✓ Saved machine type to $MACHINE_TYPE_FILE"
fi

[[ "$machine_type" == "work" && "$(uname -s)" == "Darwin" ]] || exit 0

if [[ -f "$OPTIONAL_CASKS_FILE" ]]; then
  echo "  ✓ Optional apps: $(tr '\n' ' ' < "$OPTIONAL_CASKS_FILE")(delete $OPTIONAL_CASKS_FILE to pick again)"
  exit 0
fi

casks=()
echo ""
echo "==> Which optional apps do you want on this work machine?"
while IFS= read -r line; do
  cask="$(xargs <<< "${line%%#*}")"
  [[ -z "$cask" ]] && continue
  casks+=("$cask")
  printf "  %2d) %-18s %s\n" "${#casks[@]}" "$cask" "$(sed -n 's/^[^#]*#[[:space:]]*//p' <<< "$line")"
done < "$DOTFILES_DIR/nix/optional-casks.txt"

read -rp "  Numbers to install, separated by spaces (press Enter for none): " picks
: > "$OPTIONAL_CASKS_FILE"
for pick in $picks; do
  if [[ "$pick" =~ ^[0-9]+$ && "$pick" -ge 1 && "$pick" -le ${#casks[@]} ]]; then
    grep -qxF "${casks[$((pick - 1))]}" "$OPTIONAL_CASKS_FILE" || echo "${casks[$((pick - 1))]}" >> "$OPTIONAL_CASKS_FILE"
  else
    echo "  Skipping '$pick' - not a number from the list"
  fi
done
echo "  ✓ Saved picks to $OPTIONAL_CASKS_FILE"
