dotfiles
========

Personal dotfiles and machine setup for macOS and Linux. Clone and run `install.sh` to go from a fresh machine to a fully configured environment.

## Quick start

```bash
git clone git@github.com:shyamsalimkumar/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## What it does

1. **Detects OS** — supports macOS and Linux; exits on anything else
2. **macOS** — installs Xcode CLI tools if missing
3. **Linux** — installs Homebrew prerequisites via `apt-get` if available
4. **Installs Homebrew** — if not already present
5. **Runs `brew bundle`** — `Brewfile` (cross-platform) + `Brewfile.mac` (macOS only)
6. **Installs global npm packages** — from `npm-globals.txt`, if present
7. **Sets up `~/Projects`** — see [Projects layout](#projects-layout) below
8. **Installs AI assistant tools** — see [AI assistant tools](#ai-assistant-tools) below
9. **Creates symlinks** — links all dotfiles into `$HOME`, with OS-aware paths for VS Code

## Brewfiles

| File | Used on |
|---|---|
| `Brewfile` | macOS + Linux |
| `Brewfile.mac` | macOS only (casks, colima, dockutil) |

## npm globals

`npm-globals.txt` tracks global npm packages (one per line), installed via `npm install -g` during setup.

## Syncing packages

Packages installed manually (`brew install`, `npm install -g`) don't update the tracked files automatically. Run the sync script to catch drift:

```bash
./scripts/sync-packages.sh --dry-run   # preview what would be added
./scripts/sync-packages.sh             # apply
```

It appends newly installed Homebrew taps/formulae to `Brewfile`, casks to `Brewfile.mac`, and rewrites `npm-globals.txt` from your current global npm packages. New formulae default to `Brewfile` — move any macOS-only ones to `Brewfile.mac` yourself, since the script can't infer that automatically. Review the diff before committing.

## Neovim

`neovim`, `ripgrep`, `fd`, and `lazygit` are tracked in `Brewfile`, so `install.sh` installs them. `scripts/setup-editors.sh` then handles everything else, in order:

1. Symlinks `nvim/.config/nvim` → `~/.config/nvim`. The config is a [LazyVim](https://www.lazyvim.org/) setup on top of [lazy.nvim](https://github.com/folke/lazy.nvim) — `lua/config/lazy.lua` bootstraps `lazy.nvim` itself (self-clones into `~/.local/share/nvim/lazy` on first run, nothing vendored in this repo), then imports LazyVim's default plugins plus our own specs in `lua/plugins/`: `go.lua` enables LazyVim's Go language extra (`gopls`, formatting, linting, debugging via `nvim-dap-go`, testing via `neotest-golang`), `colorscheme.lua` sets the `vscode.nvim` theme to match `vscode/settings.json`'s Dark Modern look, and `explorer.lua` enables LazyVim's Snacks file explorer (`<leader>e`) configured to always show dotfiles and gitignored files (the latter dimmed via the `SnacksPickerPathIgnored` highlight).
2. Runs `nvim --headless "+Lazy! sync" +qa` to install/update plugins non-interactively. This also drives `mason.nvim`, which installs Go tooling (`gopls`, `delve`, `goimports`, `gofumpt`, `golangci-lint`, etc.) into `~/.local/share/nvim/mason` — no need to list those in `Brewfile`.

`lazy-lock.json` (tracked alongside the config) pins exact plugin commits for reproducible installs. Re-run `./scripts/setup-editors.sh` any time to sync plugins after pulling changes.

## Symlinks

| Repo path | Destination |
|---|---|
| `.gitconfig` | `~/.gitconfig` |
| `.gitignore` | `~/.gitignore` |
| `.ssh/config` | `~/.ssh/config` |
| `zsh/zshrc` | `~/.zshrc` |
| `vim/vimrc` | `~/.vimrc` |
| `nvim/.config/nvim` | `~/.config/nvim` |
| `wezterm/.config/wezterm` | `~/.config/wezterm` |
| `tmux/.config/tmux` | `~/.config/tmux` |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `vscode/keybindings.json` | `~/Library/Application Support/Code/User/keybindings.json` |
| `helpers/personal` | `~/.local/bin/personal` |
| `helpers/work` | `~/.local/bin/work` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/settings.local.json` | `~/.claude/settings.local.json` (gitignored) |
| `claude/keybindings.json` | `~/.claude/keybindings.json` |
| `claude/skills/` | `~/.claude/skills/` |
| `claude/commands/` | `~/.claude/commands/` |
| `claude/hooks/` | `~/.claude/hooks/` |
| `claude/agents/` | `~/.claude/agents/` |
| `claude/rules/` | `~/.claude/rules/` |

## Helper scripts

Place executable scripts in `helpers/personal/` or `helpers/work/` — both are added to `$PATH` automatically.

| Folder | Committed | Purpose |
|---|---|---|
| `helpers/personal/` | Yes | Personal utilities |
| `helpers/work/` | Directory only (contents gitignored) | Work-specific scripts |

## Projects layout

All cloned repos and Go workspace sources live under `~/Projects/<host>/<org>/<repo>` (e.g. `~/Projects/github.com/shyamsalimkumar/dotfiles`) — this is the one canonical checkout location. `scripts/setup-projects.sh` enforces this for Go by making `$GOPATH/src/github.com` a symlink to `~/Projects/github.com`, so `go get`/`go install` and manual clones land in the same place. It refuses to run (and tells you what to do) if it finds a name that exists in both locations already, rather than silently merging or overwriting.

## AI assistant tools

`scripts/setup-ai-tools.sh` installs a few CLI tools built around coding agents (each check is idempotent — already-installed tools are skipped). It pipes each project's own install script from GitHub into `sh`/`npm`, so review `scripts/setup-ai-tools.sh` and each tool's install script if you want to audit what runs before you `./install.sh` on a new machine.

| Tool | What it does | Install | Usage |
|---|---|---|---|
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | Git-push proxy: runs an AI review/test/docs/lint pass in a disposable worktree before opening a PR. Plugs into whatever coding agent you already use. | `curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh \| sh` | `no-mistakes init` once per repo, then `git push no-mistakes` instead of `git push origin`. |
| [treehouse](https://github.com/kunchenguid/treehouse) | Manages a reusable pool of git worktrees per repo so you (or an agent) can drop into a dependency-warm, isolated worktree instantly. | `curl -fsSL https://kunchenguid.github.io/treehouse/install.sh \| sh` | `cd myproject && treehouse` drops you into a pooled worktree; `exit` returns it to the pool. |
| [gnhf](https://github.com/kunchenguid/gnhf) ("Good Night, Have Fun") | Autonomous agent runner — give it an objective and it drives Claude Code/Codex/etc. through iterative commits unattended, with rollback on failure. | `npm install -g gnhf` | `gnhf "reduce complexity of the codebase without changing functionality"` inside a git repo with a clean working tree. |
| [firstmate](https://github.com/kunchenguid/firstmate) | **Not a global binary and not per-project.** It's a single repo you clone once, then `cd` into and launch your agent harness (`claude`, `codex`, etc.) inside — `AGENTS.md` takes over from there. There is no separate "app" to install. When you ask it about a GitHub project, *it* clones that project under its own `projects/` subdirectory and spawns supervised sub-agents ("crewmates") in worktrees/tmux to work on it and open a PR. | `setup-ai-tools.sh` clones it once to `~/Projects/github.com/kunchenguid/firstmate` (consistent with the [Projects layout](#projects-layout) above). Requires `gh auth login` first. | `cd ~/Projects/github.com/kunchenguid/firstmate && claude`, then talk to it: `> look at my github project xyz, fix the flaky login test`; approve with `> merge it`. |

## Symlinks only

To re-run just the symlink step without installing packages:

```bash
./setupSymlinks.sh
```

## Manual step

```bash
# choose what you need from this
npx skills add vercel-labs/agent-skills
# the following might be useful
# npx skills add vercel-labs/skills@find-skills
npx skills add anthropics/skills --skill skill-creator -g
npx skills add kunchenguid/lavish-axi --skill lavish -g
npx skills add mattpocock/skills --skill codebase-design -g
npx skills add mattpocock/skills --skill teach -g
npx skills add multica-ai/andrej-karpathy-skills --skill karpathy-guidelines -g
```