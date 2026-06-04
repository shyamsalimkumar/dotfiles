#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPTS_DIR/setup-git.sh"
"$SCRIPTS_DIR/setup-shell.sh"
"$SCRIPTS_DIR/setup-editors.sh"
"$SCRIPTS_DIR/setup-claude.sh"
