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
7. **Creates symlinks** — links all dotfiles into `$HOME`, with OS-aware paths for VS Code

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

## Symlinks

| Repo path | Destination |
|---|---|
| `.gitconfig` | `~/.gitconfig` |
| `.gitignore` | `~/.gitignore` |
| `.ssh/config` | `~/.ssh/config` |
| `zsh/zshrc` | `~/.zshrc` |
| `vim/vimrc` | `~/.vimrc` |
| `nvim/.config/nvim` | `~/.config/nvim` |
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

## Symlinks only

To re-run just the symlink step without installing packages:

```bash
./setupSymlinks.sh
```
