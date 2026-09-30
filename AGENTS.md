# Dotfiles

This repo sets up the whole machine (Nix + install scripts). A new machine must come out the same from `install.sh`, so any install, config change or fix to the machine goes into this repo, not only onto this machine.

## Fixing or changing something on the machine

1. **Diagnose** first (logs, `brew info`, `which`, versions). Find the root cause before choosing a fix.
2. **Check where it's declared**: `grep -rni <name> nix scripts install.sh zsh claude pi`.
   - Declared and just broken locally (e.g. a damaged app): repair it with a one-off command (`brew reinstall --cask <name>`), say which file declares it, and stop unless the repo itself caused the breakage.
3. **Put the fix where it belongs**:
   - Mac apps (casks), Homebrew-only formulae: `nix/darwin.nix`; optional apps: `nix/optional-casks.txt`
   - CLI tools, config files, background services: `nix/home.nix` (prefer a `programs.*`/`services.*` module over a raw package)
   - Things Nix can't do (sign-ins, prompts, nvm/npm installs, writable files, registering MCP servers): `scripts/post-install.sh` or the matching `scripts/setup-*.sh`
   - Shell aliases and functions: `zsh/`
   Keep scripts idempotent (safe to re-run) and match the surrounding style.
4. **Verify**:
   - Nix changes: `git add -A`, then `cd nix && nix build --impure --no-link .#darwinConfigurations.mac.system`
   - Script changes: `bash -n <script>`, then run the new section on its own if it's safe to
   - Confirm the actual problem is gone on this machine
5. **Ship**: commit, push, open a PR against `master` with the problem, root cause and how it was tested. Merge only if asked.
6. **Apply**: tell the user the exact command, e.g. `~/.config/nix-darwin/rebuild.sh` or `scripts/post-install.sh`.
