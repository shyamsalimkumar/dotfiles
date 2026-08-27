{ pkgs, lib, ... }:

{
  # Home Manager state version
  home.stateVersion = "24.05";

  # User packages organized by category
  home.packages = with pkgs; [
    # Editors & Dev Tools
    neovim
    lazygit
    ripgrep
    fd

    # Shell & Core Tools
    bash
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship
    tmux
    direnv
    tree
    watchexec

    # AI Coding Assistants
    codex
    gemini-cli
    # Note: claude-code is added below, Linux/WSL only - already installed via
    # Homebrew cask on macOS (see darwin.nix)

    # Composio (https://composio.dev) - no nixpkgs package or flake exists yet,
    # so this wraps its npm CLI (`@composio/cli`, no local install required).
    # nodejs is scoped to this wrapper only, not exposed on $PATH - Node itself
    # is managed via nvm (see programs.zsh below), not Nix.
    (writeShellApplication {
      name = "composio";
      runtimeInputs = [ nodejs ];
      text = ''
        exec npx --yes @composio/cli@latest "$@"
      '';
    })

    # Version Managers
    mise
    uv
    # Note: nvm is shell-based, will be handled in shell config
    # Note: pyenv not in nixpkgs, using Homebrew

    # Go Ecosystem
    go
    go-task
    golangci-lint
    # Note: protoc-gen-go is a Go module, installed via go install

    # Cloud & Kubernetes
    awscli2
    # Note: cloud-sql-proxy available as google-cloud-sql-proxy
    google-cloud-sql-proxy
    docker
    docker-compose
    k9s

    # gRPC & Protobuf
    buf
    grpcui
    grpcurl

    # Git Tools
    gh
    git
    git-lfs
    delta           # Syntax-highlighting pager for git diff
    difftastic      # Structural diff tool
    # Note: transcrypt not in nixpkgs, using Homebrew

    # Data & APIs
    jq
    yq-go
    jd-diff-patch
    dyff
    hurl
    # Note: trurl not in nixpkgs, using Homebrew

    # Database Tools
    postgresql  # includes libpq

    # Utilities
    htop
    imagemagick
    yt-dlp
    gawk
    ghostscript
    libpcap
    qemu
    wget

    # Additional utilities
    curl
    gnupg
    openssh
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    claude-code
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Additional shell configuration
    initExtra = ''
      # Load personal and work aliases
      source ${../zsh/aliases.personal}
      source ${../zsh/aliases.work}
      [[ -f ${../zsh/aliases.work.local} ]] && source ${../zsh/aliases.work.local}

      # Load personal and work functions
      source ${../zsh/functions.personal}
      source ${../zsh/functions.work}
      [[ -f ${../zsh/functions.work.local} ]] && source ${../zsh/functions.work.local}

      # Starship prompt
      eval "$(starship init zsh)"

      # NVM configuration (shell-based, not via Nix)
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Auto-load .nvmrc if present
      autoload -U add-zsh-hook
      add-zsh-hook chpwd load-nvmrc
      load-nvmrc

      # Mise (version manager) activation
      eval "$(mise activate zsh)"

      # Direnv hook
      eval "$(direnv hook zsh)"

      # Go environment
      export GOPATH="$HOME/go"
      export GOBIN="$GOPATH/bin"
      export PATH="$GOBIN:$PATH"

      # Local bin directories
      export PATH="$HOME/.local/bin:$HOME/.local/bin/personal:$HOME/.local/bin/work:$PATH"

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Homebrew path (for packages not in Nix)
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

        # gcloud SDK path (if installed via Homebrew)
        if [ -f "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc" ]; then
          source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
        fi
        if [ -f "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc" ]; then
          source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
        fi
      ''}

      # kubectl completion
      command -v kubectl &> /dev/null && source <(kubectl completion zsh)

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Colima Docker configuration
        export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
      ''}

      # Colorize output
      export CLICOLOR=1
      export LSCOLORS=ExFxBxDxCxegedabagacad

      # Man page colors
      export LESS_TERMCAP_mb=$'\e[1;32m'
      export LESS_TERMCAP_md=$'\e[1;32m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[01;33m'
      export LESS_TERMCAP_ue=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;4;31m'
    '';
  };

  # Starship configuration (adopted from reference with current customization)
  programs.starship = {
    enable = true;
    settings = {
      # Reference config (purple prompt, command duration)
      add_newline = true;
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration = {
        min_time = 500;
        format = "[$duration]($style) ";
      };

      # Current starship.toml config (documented as reference)
      # Original config used:
      # success_symbol = "[➜](bold green)"
      # disabled package module
      # Adopting reference config as active configuration
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    # Note: userName and userEmail should be configured in ~/.gitconfig.local
    # See README Prerequisites section for setup instructions

    extraConfig = {
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
      push = {
        default = "simple";
      };

      # Delta - syntax-highlighting pager for git diff
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      # Multi-company work profile support via includeIf
      # Automatically switches git config based on directory
      includeIf."gitdir:~/work/company-a/".path = "~/.gitconfig-company-a";
      includeIf."gitdir:~/work/company-b/".path = "~/.gitconfig-company-b";
    };
  };

  # Direnv configuration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Out-of-store symlinks for live-editable configs
  # These configs can be edited without rebuilding
  home.file = {
    # Neovim config (LazyVim setup)
    ".config/nvim".source = ../nvim/.config/nvim;

    # Wezterm config
    ".config/wezterm".source = ../wezterm/.config/wezterm;

    # Vim config
    ".vimrc".source = ../vim/vimrc;

    # Tmux config
    ".config/tmux".source = ../tmux/.config/tmux;

    # Claude settings and skills
    ".claude/settings.json".source = ../claude/settings.json;
    ".claude/keybindings.json".source = ../claude/keybindings.json;
    ".claude/skills".source = ../claude/skills;
    ".claude/agents".source = ../claude/agents;
    ".claude/commands".source = ../claude/commands;
    ".claude/hooks".source = ../claude/hooks;
    ".claude/rules".source = ../claude/rules;

    # Global AGENTS.md (shared instructions for all AI assistants)
    ".claude/CLAUDE.md".source = ../home/AGENTS.md;
    ".codex/AGENTS.md".source = ../home/AGENTS.md;
    ".config/opencode/AGENTS.md".source = ../home/AGENTS.md;

    # SSH config - generic host aliases only
    # For host-specific settings, use ~/.ssh/config.local (not tracked)
    ".ssh/config".source = ../.ssh/config;

    # Git configuration examples (user creates .gitconfig.local)
    ".gitconfig.local.example".source = ../.gitconfig.local.example;

    # Helper scripts (PATH for these is set in initExtra above)
    ".local/bin/personal".source = ../helpers/personal;
    ".local/bin/work".source = ../helpers/work;
  }
  # VSCode settings (NAVS plugins) - path differs between macOS and Linux
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Application Support/Code/User/settings.json".source = ../vscode/settings.json;
    "Library/Application Support/Code/User/keybindings.json".source = ../vscode/keybindings.json;
  }
  // lib.optionalAttrs pkgs.stdenv.isLinux {
    ".config/Code/User/settings.json".source = ../vscode/settings.json;
    ".config/Code/User/keybindings.json".source = ../vscode/keybindings.json;
  };
}
