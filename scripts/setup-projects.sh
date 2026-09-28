#!/usr/bin/env bash
set -euo pipefail

PROJECTS_GITHUB="$HOME/Projects/github.com"
GOPATH="$(go env GOPATH 2>/dev/null || echo "$HOME/go")"
GO_SRC_GITHUB="$GOPATH/src/github.com"

echo "==> Setting up ~/Projects/github.com..."
mkdir -p "$PROJECTS_GITHUB"

if [[ -L "$GO_SRC_GITHUB" ]]; then
  echo "  $GO_SRC_GITHUB is already a symlink, skipping"
  exit 0
fi

if [[ -d "$GO_SRC_GITHUB" ]]; then
  echo "  Merging $GO_SRC_GITHUB into $PROJECTS_GITHUB..."
  conflicts=()
  for entry in "$GO_SRC_GITHUB"/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    [[ -e "$PROJECTS_GITHUB/$name" ]] && conflicts+=("$name")
  done

  if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "  ERROR: refusing to auto-merge — these entries exist in both $GO_SRC_GITHUB and $PROJECTS_GITHUB:"
    printf '    %s\n' "${conflicts[@]}"
    echo "  Compare and merge them by hand, then re-run this script."
    exit 1
  fi

  for entry in "$GO_SRC_GITHUB"/*; do
    [[ -e "$entry" ]] || continue
    mv "$entry" "$PROJECTS_GITHUB/"
  done
  rmdir "$GO_SRC_GITHUB"
fi

mkdir -p "$(dirname "$GO_SRC_GITHUB")"
ln -sfn "$PROJECTS_GITHUB" "$GO_SRC_GITHUB"
echo "  Linked $GO_SRC_GITHUB → $PROJECTS_GITHUB"
