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
2. **Asks personal or work** — see [Work machines](#work-machines) below
3. **macOS only** — installs Xcode CLI tools and Homebrew (used by `nix-darwin` for the
   handful of packages/casks not available in nixpkgs, declared in `nix/darwin.nix`)
4. **Installs Nix and builds the system configuration** — `nix-darwin` on macOS,
   standalone `home-manager` on Linux/WSL (see [nix/README.md](nix/README.md))
5. **Sets up `~/Projects`** — see [Projects layout](#projects-layout) below
6. **Installs AI assistant tools** — see [AI assistant tools](#ai-assistant-tools) below
7. **Runs post-install tasks** — git identity prompt,
   GitHub SSH/GPG keys, Neovim plugin sync, Claude plugin installation

Packages, shell config, and dotfile symlinks are all declared in `nix/home.nix` and
applied by the Nix build in step 4 — see [nix/README.md](nix/README.md) for what's
symlinked where.

## Work machines

`scripts/setup-machine.sh` (the first step of `install.sh`) asks once whether
the machine is personal or work, and saves the answer in
`~/.config/dotfiles/machine`.

On a work Mac it also lists the optional apps in `nix/optional-casks.txt`
(password manager, chat apps, Spotify, and so on) and asks which to install;
pressing Enter installs none. The picks are saved in
`~/.config/dotfiles/optional-casks`, and `nix/darwin.nix` installs only those.
Core dev apps and all command-line tools install everywhere. Personal machines
get every app. To pick again, delete that file, run `scripts/setup-machine.sh`,
then `nix/rebuild.sh`.

Work machines also get a `~/.ssh/github-work` key titled
`work-<hostname> (dotfiles)` on GitHub, and every key registered with GitHub is
recorded in `~/.config/dotfiles/registered` for offboarding.

## Leaving a job (offboarding)

Before handing a work laptop back, run this on it:

```bash
./scripts/offboard.sh
```

It deletes the recorded SSH/GPG keys from GitHub, then (after a confirmation)
logs the machine out of gh, git's credential store, gcloud, AWS SSO, npm, Docker,
1Password CLI and Claude Code. Key files stay on disk. It ends with a checklist of
things only a browser can do (GitHub sessions/apps/tokens, Google and Apple
devices, and so on).

If the laptop is already gone, run it on another machine: with no receipt it
lists your GitHub keys so you can pick the old ones, and you answer "no" to the
log-out step so the current machine stays logged in.

## Neovim

The config is a [LazyVim](https://www.lazyvim.org/) setup on top of [lazy.nvim](https://github.com/folke/lazy.nvim) — `lua/config/lazy.lua` bootstraps `lazy.nvim` itself (self-clones into `~/.local/share/nvim/lazy` on first run, nothing vendored in this repo), then imports LazyVim's default plugins plus our own specs in `lua/plugins/`: `go.lua` enables LazyVim's Go language extra (`gopls`, formatting, linting, debugging via `nvim-dap-go`, testing via `neotest-golang`), `colorscheme.lua` sets the `vscode.nvim` theme to match `vscode/settings.json`'s Dark Modern look, and `explorer.lua` enables LazyVim's Snacks file explorer (`<leader>e`) configured to always show dotfiles and gitignored files (the latter dimmed via the `SnacksPickerPathIgnored` highlight).

`nix/home.nix` symlinks `nvim/.config/nvim` → `~/.config/nvim` as an out-of-store symlink, so the config is live-editable without a Nix rebuild. `scripts/post-install.sh` runs `nvim --headless "+Lazy! sync" +qa` to install/update plugins non-interactively, which also drives `mason.nvim` to install Go tooling (`gopls`, `delve`, `goimports`, `gofumpt`, `golangci-lint`, etc.) into `~/.local/share/nvim/mason`.

`lazy-lock.json` (tracked alongside the config) pins exact plugin commits for reproducible installs. Re-run `scripts/post-install.sh` any time to sync plugins after pulling changes.

## Shell configuration

Zsh config itself lives inline in `programs.zsh.initContent` in `nix/home.nix` (aliases/functions are separate tracked files, `zsh/aliases.*` and `zsh/functions.*`, sourced from there). Shell prompt is provided by [Starship](https://starship.rs/), configured via `programs.starship` in `nix/home.nix`.

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

All cloned repos, for every language, live under `~/Projects/<host>/<org>/<repo>` (e.g. `~/Projects/github.com/shyamsalimkumar/dotfiles`) — this is the one canonical checkout location.

Go's own tooling doesn't know about that convention, though: `go get`, `go install`, and GOPATH-aware code expect source to live at the very specific path `$GOPATH/src/<import-path>` (e.g. `~/go/src/github.com/someuser/somerepo`). Without a bridge between the two, every Go repo would need two separate copies - one for Go's tools, one for everything else - which would drift out of sync. `scripts/setup-projects.sh` avoids that by making `$GOPATH/src/github.com` a *symlink* to `~/Projects/github.com` instead: there's really only one copy of anything on disk, but Go's tools still find it exactly where they expect to look, and manual clones land in the same place either way.

If it finds a repo name that already exists in *both* locations as separate real directories (not yet merged), it refuses to auto-merge that one (and tells you what to do), rather than silently overwriting - everything else gets merged into `~/Projects/github.com` automatically.

## AI assistant configuration

Global instructions for AI coding assistants are in `home/AGENTS.md`. `nix/home.nix` symlinks it to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.config/opencode/AGENTS.md`. This file provides workflow guidelines, development standards, and language-specific practices shared across all AI assistants.

Claude-specific settings, keybindings, and skills are in the `claude/` directory:
- `claude/settings.json`: Claude Code settings
- `claude/keybindings.json`: Keyboard shortcuts
- `claude/skills/`: Custom skills (ai-review, security-review, etc.) plus the `mattpocock-skills` plugin (see [Manual step](#manual-step) below)
- `claude/agents/`, `claude/commands/`, `claude/hooks/`, `claude/rules/`: Custom agents, slash commands, hooks, and rules

`nix/home.nix` symlinks all of these into `~/.claude/` during setup.

The coding-assistant CLIs themselves — `claude` ([Claude Code](https://github.com/anthropics/claude-code)), `codex` ([OpenAI Codex CLI](https://github.com/openai/codex)), and `gemini` ([Gemini CLI](https://github.com/google-gemini/gemini-cli)) — are Nix packages in `nix/home.nix`'s `home.packages`. `claude-code` is Linux/WSL-only there since macOS already gets it via the Homebrew cask in `darwin.nix`.

`composio` ([Composio](https://composio.dev), agent-to-app integrations) has no nixpkgs package or flake yet, so `nix/home.nix` declares it as a `writeShellApplication` wrapper around its npm CLI (`npx @composio/cli`) instead of an imperative `npm install -g`. Node is pulled in only for that wrapper, not exposed on `$PATH` generally — Node itself stays nvm-managed (see [Shell configuration](#shell-configuration)).

## AI assistant tools

`scripts/setup-ai-tools.sh` installs a few CLI tools built around coding agents (each check is idempotent — already-installed tools are skipped). It pipes each project's own install script from GitHub into `sh`/`npm`, so review `scripts/setup-ai-tools.sh` and each tool's install script if you want to audit what runs before you `./install.sh` on a new machine.

| Tool | What it does | Install | Usage |
|---|---|---|---|
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | Git-push proxy: runs an AI review/test/docs/lint pass in a disposable worktree before opening a PR. Plugs into whatever coding agent you already use. | `curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh \| sh` | `no-mistakes init` once per repo, then `git push no-mistakes` instead of `git push origin`. |
| [treehouse](https://github.com/kunchenguid/treehouse) | Manages a reusable pool of git worktrees per repo so you (or an agent) can drop into a dependency-warm, isolated worktree instantly. | `curl -fsSL https://kunchenguid.github.io/treehouse/install.sh \| sh` | `cd myproject && treehouse` drops you into a pooled worktree; `exit` returns it to the pool. |
| [gnhf](https://github.com/kunchenguid/gnhf) ("Good Night, Have Fun") | Autonomous agent runner — give it an objective and it drives Claude Code/Codex/etc. through iterative commits unattended, with rollback on failure. | `npm install -g gnhf` | `gnhf "reduce complexity of the codebase without changing functionality"` inside a git repo with a clean working tree. |
| [firstmate](https://github.com/kunchenguid/firstmate) | **Not a global binary and not per-project.** It's a single repo you clone once, then `cd` into and launch your agent harness (`claude`, `codex`, etc.) inside — `AGENTS.md` takes over from there. There is no separate "app" to install. When you ask it about a GitHub project, *it* clones that project under its own `projects/` subdirectory and spawns supervised sub-agents ("crewmates") in worktrees/tmux to work on it and open a PR. | `setup-ai-tools.sh` clones it once to `~/Projects/github.com/kunchenguid/firstmate` (consistent with the [Projects layout](#projects-layout) above). Requires `gh auth login` first. | `cd ~/Projects/github.com/kunchenguid/firstmate && claude`, then talk to it: `> look at my github project xyz, fix the flaky login test`; approve with `> merge it`. |

## Blender MCP

On macOS, `scripts/post-install.sh` sets up [MCP for Blender](https://github.com/ahujasid/blender-mcp):
it registers `uvx mcp-for-blender` with Claude Code, the Claude desktop app
and Codex, and installs the Blender add-on. Enabling the add-on and clicking
**Start MCP Server** inside Blender are manual; the script prints those
steps at the end of its run.

## Web search

Claude Code's built-in `WebSearch` tool is disabled (`permissions.deny` in
`claude/settings.json`) in favor of
[Agent Reach](https://github.com/Panniantong/agent-reach) — an open-source,
free CLI/MCP toolkit that gives the agent broader internet access (web
search, arbitrary webpages, YouTube, RSS, and more) than the built-in tool
alone.

```bash
brew install pipx
pipx install https://github.com/Panniantong/agent-reach/archive/main.zip
agent-reach install --env=auto
npm install -g mcporter
mcporter config add exa https://mcp.exa.ai/mcp --scope home
```

The last two lines register Exa's MCP server, which is what actually backs
web search once `WebSearch` is off — run `agent-reach doctor` to check
channel status. This is a per-machine setup step, not automated by
`install.sh`.

## Manual step

```bash
# choose what you need from this
npx skills add vercel-labs/agent-skills
# the following might be useful
# npx skills add vercel-labs/skills@find-skills
npx skills add anthropics/skills --skill skill-creator -g
npx skills add kunchenguid/lavish-axi --skill lavish -g
```

Matt Pocock's skills (grill-me, grill-with-docs, handoff, implement,
improve-codebase-architecture, tdd, to-tickets, wayfinder, codebase-design,
teach, and more) and karpathy-guidelines come from the `mattpocock-skills` and
`andrej-karpathy-skills` Claude Code plugins instead of `npx skills add` — see
`enabledPlugins` in `claude/settings.json`, installed automatically by
`scripts/setup-claude.sh` / `scripts/post-install.sh`.

[Pi](https://github.com/earendil-works/pi-coding-agent) (`npm-globals.txt`)
has no plugin/marketplace system, so those same skills are still installed
there via `npx skills add ... -g` — `scripts/setup-claude.sh` /
`scripts/post-install.sh` mirror every skill under `~/.agents/skills` into
`~/.pi/agent/skills` on every run.