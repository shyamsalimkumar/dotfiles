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
6. **Creates symlinks** — links all dotfiles into `$HOME`, with OS-aware paths for VS Code

## Brewfiles

| File | Used on |
|---|---|
| `Brewfile` | macOS + Linux |
| `Brewfile.mac` | macOS only (casks, colima, dockutil) |

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
