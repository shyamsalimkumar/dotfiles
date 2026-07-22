dotfiles
========

Personal dotfiles and machine setup for macOS and Linux (including WSL2), managed
declaratively with Nix — [nix-darwin](https://github.com/LnL7/nix-darwin) on macOS,
standalone [home-manager](https://github.com/nix-community/home-manager) on Linux/WSL.

## Quick start

```bash
git clone git@github.com:shyamsalimkumar/dotfiles.git ~/dotfiles
cd ~/dotfiles
# Copy and edit .gitconfig.local.example with your personal git information
cp .gitconfig.local.example ~/.gitconfig.local
# Edit ~/.gitconfig.local with your name and email
./install.sh
```

For the Nix configuration itself — structure, packages, symlinks, work profiles,
validation, rollback — see [nix/README.md](nix/README.md).

## What `install.sh` does

1. **Detects OS** — supports macOS and Linux/WSL2; exits on anything else
2. **macOS only** — installs Xcode CLI tools and Homebrew (used by `nix-darwin` for the
   handful of packages/casks not available in nixpkgs, declared in `nix/darwin.nix`)
3. **Installs Nix and builds the system configuration** — `nix-darwin` on macOS,
   standalone `home-manager` on Linux/WSL (see [nix/README.md](nix/README.md))
4. **Sets up `~/Projects`** — see [Projects layout](#projects-layout) below
5. **Installs AI assistant tools** — see [AI assistant tools](#ai-assistant-tools) below
6. **Runs post-install tasks** — git identity prompt, Neovim plugin sync, Claude plugin
   installation

Packages, shell config, and dotfile symlinks are all declared in `nix/home.nix` and
applied by the Nix build in step 3 — see [nix/README.md](nix/README.md) for what's
symlinked where.

## Neovim

The config is a [LazyVim](https://www.lazyvim.org/) setup on top of [lazy.nvim](https://github.com/folke/lazy.nvim) — `lua/config/lazy.lua` bootstraps `lazy.nvim` itself (self-clones into `~/.local/share/nvim/lazy` on first run, nothing vendored in this repo), then imports LazyVim's default plugins plus our own specs in `lua/plugins/`: `go.lua` enables LazyVim's Go language extra (`gopls`, formatting, linting, debugging via `nvim-dap-go`, testing via `neotest-golang`), and `colorscheme.lua` sets the `vscode.nvim` theme to match `vscode/settings.json`'s Dark Modern look.

`nix/home.nix` symlinks `nvim/.config/nvim` → `~/.config/nvim` as an out-of-store symlink, so the config is live-editable without a Nix rebuild. `scripts/post-install.sh` runs `nvim --headless "+Lazy! sync" +qa` to install/update plugins non-interactively, which also drives `mason.nvim` to install Go tooling (`gopls`, `delve`, `goimports`, `gofumpt`, `golangci-lint`, etc.) into `~/.local/share/nvim/mason`.

`lazy-lock.json` (tracked alongside the config) pins exact plugin commits for reproducible installs. Re-run `scripts/post-install.sh` any time to sync plugins after pulling changes.

## Shell configuration

Zsh configuration is in `zsh/zshrc` (aliases/functions in `zsh/aliases.*` and `zsh/functions.*`), sourced directly by `programs.zsh` in `nix/home.nix`. Shell prompt is provided by [Starship](https://starship.rs/), configured via `programs.starship` in `nix/home.nix`.

## Tmux

Tmux configuration is in `tmux/.config/tmux/tmux.conf`. Key features:
- **Prefix key**: `Ctrl+B` (default tmux prefix)
- Vi-style copy mode
- Pane splits preserve current path (`|` for horizontal, `-` for vertical)
- Window list shows directory names for easier identification
- Pane borders labeled with directory

## Helper scripts

Place executable scripts in `helpers/personal/` or `helpers/work/`.

| Folder | Committed | Purpose |
|---|---|---|
| `helpers/personal/` | Yes | Personal utilities |
| `helpers/work/` | Directory only (contents gitignored) | Work-specific scripts |

`nix/home.nix` symlinks both into `~/.local/bin/`, which is on `$PATH`.

## Projects layout

All cloned repos and Go workspace sources live under `~/Projects/<host>/<org>/<repo>` (e.g. `~/Projects/github.com/shyamsalimkumar/dotfiles`) — this is the one canonical checkout location. `scripts/setup-projects.sh` enforces this for Go by making `$GOPATH/src/github.com` a symlink to `~/Projects/github.com`, so `go get`/`go install` and manual clones land in the same place. It refuses to run (and tells you what to do) if it finds a name that exists in both locations already, rather than silently merging or overwriting.

## AI assistant configuration

Global instructions for AI coding assistants are in `home/AGENTS.md`. `nix/home.nix` symlinks it to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.config/opencode/AGENTS.md`. This file provides workflow guidelines, development standards, and language-specific practices shared across all AI assistants.

Claude-specific settings, keybindings, and skills are in the `claude/` directory:
- `claude/settings.json`: Claude Code settings
- `claude/keybindings.json`: Keyboard shortcuts
- `claude/skills/`: Custom skills (18 skills including ai-review, tdd, security-review, etc.)
- `claude/agents/`, `claude/commands/`, `claude/hooks/`, `claude/rules/`: Custom agents, slash commands, hooks, and rules

`nix/home.nix` symlinks all of these into `~/.claude/` during setup.

The coding-assistant CLIs themselves — `claude` ([Claude Code](https://github.com/anthropics/claude-code)), `codex` ([OpenAI Codex CLI](https://github.com/openai/codex)), and `gemini` ([Gemini CLI](https://github.com/google-gemini/gemini-cli)) — are Nix packages in `nix/home.nix`'s `home.packages`. `claude-code` is Linux/WSL-only there since macOS already gets it via the Homebrew cask in `darwin.nix`.

## AI assistant tools

`scripts/setup-ai-tools.sh` installs a few CLI tools built around coding agents (each check is idempotent — already-installed tools are skipped). It pipes each project's own install script from GitHub into `sh`/`npm`, so review `scripts/setup-ai-tools.sh` and each tool's install script if you want to audit what runs before you `./install.sh` on a new machine.

| Tool | What it does | Install | Usage |
|---|---|---|---|
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | Git-push proxy: runs an AI review/test/docs/lint pass in a disposable worktree before opening a PR. Plugs into whatever coding agent you already use. | `curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh \| sh` | `no-mistakes init` once per repo, then `git push no-mistakes` instead of `git push origin`. |
| [treehouse](https://github.com/kunchenguid/treehouse) | Manages a reusable pool of git worktrees per repo so you (or an agent) can drop into a dependency-warm, isolated worktree instantly. | `curl -fsSL https://kunchenguid.github.io/treehouse/install.sh \| sh` | `cd myproject && treehouse` drops you into a pooled worktree; `exit` returns it to the pool. |
| [gnhf](https://github.com/kunchenguid/gnhf) ("Good Night, Have Fun") | Autonomous agent runner — give it an objective and it drives Claude Code/Codex/etc. through iterative commits unattended, with rollback on failure. | `npm install -g gnhf` | `gnhf "reduce complexity of the codebase without changing functionality"` inside a git repo with a clean working tree. |
| [firstmate](https://github.com/kunchenguid/firstmate) | **Not a global binary and not per-project.** It's a single repo you clone once, then `cd` into and launch your agent harness (`claude`, `codex`, etc.) inside — `AGENTS.md` takes over from there. There is no separate "app" to install. When you ask it about a GitHub project, *it* clones that project under its own `projects/` subdirectory and spawns supervised sub-agents ("crewmates") in worktrees/tmux to work on it and open a PR. | `setup-ai-tools.sh` clones it once to `~/Projects/github.com/kunchenguid/firstmate` (consistent with the [Projects layout](#projects-layout) above). Requires `gh auth login` first. | `cd ~/Projects/github.com/kunchenguid/firstmate && claude`, then talk to it: `> look at my github project xyz, fix the flaky login test`; approve with `> merge it`. |

## Manual step

```bash
# choose what you need from this
npx skills add vercel-labs/agent-skills
# the following might be useful
# npx skills add vercel-labs/skills@find-skills
npx skills add anthropics/skills --skill skill-creator -g
npx skills add kunchenguid/lavish-axi --skill lavish -g
```