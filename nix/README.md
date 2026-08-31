# Nix Configuration (macOS + Linux/WSL)

Declarative system configuration using nix-darwin + home-manager on macOS, and
standalone home-manager on native Linux or any WSL2 distro. `home.nix` (packages,
shell, git, direnv config) is shared between both platforms; only the handful of
macOS-only bits (Homebrew paths, Colima, VSCode config path) are guarded per
platform.

## Structure

```
nix/
├── flake.nix              # Entry point - dependency wiring only
├── darwin.nix             # macOS system configuration
├── home.nix               # User packages & shell/git/direnv configuration (shared)
├── bootstrap.sh           # First-time setup script (macOS)
├── rebuild.sh             # Daily rebuild script (macOS)
├── bootstrap-linux.sh     # First-time setup script (Linux/WSL)
├── rebuild-linux.sh       # Daily rebuild script (Linux/WSL)
├── modules/               # Modular configuration components
│   └── work-profiles.nix  # Multi-company profile logic (macOS only, see below)
└── profiles/              # Work profile configurations
    ├── personal.nix       # Placeholder for personal-specific config
    ├── company-a.nix      # Opt-in via local config
    └── company-b.nix      # Opt-in via local config
```

## Prerequisites

Before running bootstrap, ensure you have:

1. **Git configured locally**: Copy `.gitconfig.local.example` (from the repo root) to `~/.gitconfig.local` and update with your personal information:
   ```bash
   # From the dotfiles repo root:
   cp .gitconfig.local.example ~/.gitconfig.local
   # Edit ~/.gitconfig.local with your name and email
   ```
   The main `.gitconfig` includes this file via `[include] path = ~/.gitconfig.local`.

2. **Xcode Command Line Tools** (macOS): Will be installed automatically by bootstrap if missing

## Quick Start

### macOS

First-time setup:
```bash
cd nix
./bootstrap.sh
```

This will:
1. Install Determinate Nix (if not already installed)
2. Create symlink: `~/.config/nix-darwin` → `nix/`
3. Run first `darwin-rebuild switch`

Daily rebuild:
```bash
cd nix
./rebuild.sh
```

Or from anywhere:
```bash
darwin-rebuild switch --flake ~/.config/nix-darwin#mac
```

### Linux / WSL

This targets **home-manager only** — it manages your shell, dotfiles, and CLI
tools, not the whole system. Works the same whether it's a native Linux box or
a WSL2 distro (Ubuntu, Debian, etc.) — WSL2 is just a Linux userland, there's
nothing Windows-side to configure. Just make sure Nix can be installed inside
that Linux environment (true for any standard WSL2 distro).

First-time setup:
```bash
cd nix
./bootstrap-linux.sh
```

This will:
1. Install Determinate Nix (if not already installed)
2. Create symlink: `~/.config/home-manager` → `nix/`
3. Run first `home-manager switch --flake .#linux`

Daily rebuild:
```bash
cd nix
./rebuild-linux.sh
```

Or from anywhere:
```bash
home-manager switch --flake ~/.config/home-manager#linux
```

**Known gaps on Linux/WSL** (not covered by this branch):
- Multi-company work profiles (`modules/work-profiles.nix`) are wired through
  nix-darwin's `home-manager.users.<user>` option and a hardcoded `/Users/...`
  local-config path — they only apply to the macOS output for now.
- Only `x86_64-linux` is wired up in `flake.nix`. Add `aarch64-linux` the same
  way if you ever need it on ARM.
- This does not manage the Linux system itself (packages outside your home
  directory, services, etc.). If you want the whole WSL2 distro declaratively
  managed the way `darwin.nix` manages macOS, look into
  [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) — that replaces your
  WSL distro with actual NixOS and lets you write a real `configuration.nix`
  for it. That's a bigger, separate step from what's set up here.

## Key Features

### Out-of-Store Symlinks
Live-editable configs that don't require rebuilds:
- Neovim config: Edit `nvim/.config/nvim/` directly
- Wezterm config: Edit `wezterm/.config/wezterm/` directly
- Vim config: Edit `vim/vimrc` directly
- Tmux config: Edit `tmux/.config/tmux/tmux.conf` directly
- Starship config: Edit `starship/.config/starship.toml` directly (note: overridden by `home.nix` settings when using nix-darwin)

### macOS System Defaults
All system preferences declared in `darwin.nix`:
- Dark mode enabled
- Fast key repeat
- Hidden menu bar
- Dock auto-hide
- Finder list view
- Desktop icons hidden
- Trackpad tap-to-click

### Multi-Company Work Profiles (macOS only)
Supports working with multiple companies simultaneously with isolated configurations.
Not yet available on the Linux/WSL output — see "Known gaps" above.

#### Setup

1. **Copy the example local config**:
```bash
cp ~/.config/nix-darwin/local.nix.example ~/.config/nix-darwin/local.nix
```

2. **Enable desired profiles** by editing `local.nix`:
```nix
{
  profiles = {
    companyA.enable = true;   # Set to true to enable
    companyB.enable = false;  # Set to false to disable
  };
}
```

3. **Rebuild** to apply changes:
```bash
darwin-rebuild switch --flake ~/.config/nix-darwin#mac
```

#### Profile Structure

Each company profile (`profiles/company-a.nix`, `profiles/company-b.nix`) can include:
- Company-specific packages
- Git configuration (via `.gitconfig-company-a`)
- Shell aliases
- SSH configurations

#### Credential Management

**IMPORTANT**: Credentials are NEVER auto-loaded. Use explicit functions:

```bash
# Load Company A environment
work-a

# Load Company B environment
work-b

# Clear all work environments
work-clear
```

These functions set:
- `AWS_PROFILE`
- `GCP_PROJECT`
- `SSH_AUTH_SOCK`

#### Git Directory-Based Configuration

Git automatically uses the correct profile based on directory:

```bash
# In ~/work/company-a/project/ → uses Company A git config
# In ~/work/company-b/project/ → uses Company B git config
# Anywhere else → uses personal git config
```

This is configured via `includeIf` in git configuration:
```gitconfig
[includeIf "gitdir:~/work/company-a/"]
    path = ~/.gitconfig-company-a
```

#### Creating a New Profile

1. Create `profiles/your-company.nix` based on the templates
2. Add option in `modules/work-profiles.nix`
3. Update `local.nix` to enable the profile
4. Rebuild

## Package Management

Packages are primarily managed through Nix (`home.packages` in `home.nix`).

Homebrew is used only for packages unavailable in nixpkgs:
- Cleanup mode: `uninstall` (safe during migration)
- Future mode: `zap` (strict declarative mode)

## Validation

```bash
# Check flake validity (evaluates both platforms)
nix flake check

# macOS: build without switching
nix build .#darwinConfigurations.mac.system

# macOS: preview changes
darwin-rebuild build --flake ~/.config/nix-darwin#mac

# Linux/WSL: build without switching
nix build .#homeConfigurations.linux.activationPackage

# Linux/WSL: preview changes
home-manager build --flake ~/.config/home-manager#linux
```

## Rollback

If something breaks:
```bash
# List generations
darwin-rebuild --list-generations

# Rollback to previous generation
darwin-rebuild --rollback
```

## References

- nix-darwin: https://github.com/LnL7/nix-darwin
- home-manager: https://github.com/nix-community/home-manager
- nixpkgs: https://search.nixos.org/packages
- NixOS-WSL (full system-level alternative for WSL2): https://github.com/nix-community/NixOS-WSL
- Reference implementation: kunchenguid/dotfiles
