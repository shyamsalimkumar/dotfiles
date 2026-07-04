#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/Brewfile"
BREWFILE_MAC="$DOTFILES_DIR/Brewfile.mac"
NPM_GLOBALS="$DOTFILES_DIR/npm-globals.txt"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

is_tracked() {
  grep -q "\"$1\"" "$BREWFILE" "$BREWFILE_MAC" 2>/dev/null
}

sync_brew() {
  echo "==> Homebrew taps"
  while read -r tap; do
    [[ -z "$tap" || "$tap" == "homebrew/core" || "$tap" == "homebrew/cask" ]] && continue
    if ! is_tracked "$tap"; then
      echo "  + tap \"$tap\" -> Brewfile"
      [[ "$DRY_RUN" -eq 0 ]] && printf 'tap "%s"\n' "$tap" >> "$BREWFILE"
    fi
  done < <(brew tap)

  # brew leaves = top-level formulae only, so dependencies pulled in
  # automatically don't get tracked alongside the tool that needs them.
  echo "==> Homebrew formulae (leaves)"
  while read -r formula; do
    [[ -z "$formula" ]] && continue
    if ! is_tracked "$formula"; then
      echo "  + brew \"$formula\" -> Brewfile (move to Brewfile.mac if macOS-only)"
      [[ "$DRY_RUN" -eq 0 ]] && printf 'brew "%s"\n' "$formula" >> "$BREWFILE"
    fi
  done < <(brew leaves)

  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "==> Homebrew casks"
    while read -r cask; do
      [[ -z "$cask" ]] && continue
      if ! is_tracked "$cask"; then
        echo "  + cask \"$cask\" -> Brewfile.mac"
        [[ "$DRY_RUN" -eq 0 ]] && printf 'cask "%s"\n' "$cask" >> "$BREWFILE_MAC"
      fi
    done < <(brew list --cask)
  fi
}

sync_npm() {
  echo "==> Global npm packages"
  if ! command -v npm >/dev/null 2>&1; then
    echo "  npm not found, skipping"
    return
  fi

  local current
  current="$(npm list -g --depth=0 --parseable 2>/dev/null \
    | tail -n +2 \
    | sed 's|.*/node_modules/||' \
    | grep -vE '^(npm|corepack)$' \
    | sort -u)"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    diff <(cat "$NPM_GLOBALS" 2>/dev/null) <(echo "$current") 2>/dev/null \
      | grep '^>' | sed 's/^> /  + /' || true
  else
    echo "$current" > "$NPM_GLOBALS"
  fi
}

sync_brew
sync_npm

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "==> Dry run only, no files changed. Re-run without --dry-run to apply."
else
  echo "==> Done. Review with: git diff Brewfile Brewfile.mac npm-globals.txt"
fi
