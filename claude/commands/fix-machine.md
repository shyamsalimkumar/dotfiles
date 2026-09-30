Install, configure, or fix something on this machine so the fix lives in the dotfiles repo and a fresh machine gets it from `install.sh`, instead of only patching this machine.

Task: `$ARGUMENTS` (if empty, use what the user just asked for).

Dotfiles repo: `~/Projects/github.com/shyamsalimkumar/dotfiles`.

1. **Diagnose** the problem on this machine first (logs, `brew info`, `which`, versions). Find the root cause before choosing a fix.
2. **Check the repo** for where the thing is already declared: `grep -rni <name>` across `nix/`, `scripts/`, `install.sh`, `zsh/`, `claude/`, `pi/`.
   - Declared and just broken locally (e.g. a damaged app): repair it with a one-off command (`brew reinstall --cask <name>`), tell the user which file declares it, and stop unless the repo itself caused the breakage.
3. **Pick where the fix belongs**:
   - Mac apps (casks), Homebrew-only formulae: `nix/darwin.nix`; optional apps: `nix/optional-casks.txt`
   - CLI tools, config files, background services: `nix/home.nix` (prefer a `programs.*`/`services.*` module over a raw package)
   - Things Nix can't do (sign-ins, prompts, nvm/npm installs, writable files, registering MCP servers): `scripts/post-install.sh` or the matching `scripts/setup-*.sh`
   - Shell aliases/functions: `zsh/`
   Keep scripts idempotent (safe to re-run) and match the surrounding style.
4. **Branch**: create a worktree at `./worktrees/<branch-name>` inside the repo, branched from an up-to-date `master`.
5. **Verify** before committing:
   - Nix changes: `git add -A` in the worktree, then `cd nix && nix build --impure --no-link .#darwinConfigurations.mac.system`
   - Script changes: `bash -n <script>`, then run the new section on its own if it's safe to
   - Confirm the actual problem is gone on this machine
6. **Ship**: commit (no AI attribution), push, open a PR against `master` explaining the problem, the root cause and how it was tested. Only merge if the user asked.
7. **Apply locally** if not already applied: tell the user the exact command, e.g. `~/.config/nix-darwin/rebuild.sh` or `<repo>/scripts/post-install.sh`.

Report: what was wrong, which repo files changed, the PR link, and what the user still has to run.
