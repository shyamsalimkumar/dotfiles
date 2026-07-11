{ pkgs, ... }:

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

    # Version Managers
    mise
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
    # Note: tbm from custom tap, using Homebrew

    # gRPC & Protobuf
    buf
    grpcui
    grpcurl

    # Git Tools
    gh
    git
    git-lfs
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
    # Note: pgsync not in nixpkgs, using Homebrew
    # Note: golang-migrate available as migrate
    migrate

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
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Basic aliases (from zsh/aliases.personal)
    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # ls aliases
      "ls" = "ls -G";
      "ll" = "ls -lah";
      "la" = "ls -A";
      "l" = "ls -CF";

      # Git shortcuts
      "g" = "git";
      "gs" = "git status";
      "ga" = "git add";
      "gc" = "git commit";
      "gp" = "git push";
      "gl" = "git pull";
      "gd" = "git diff";
      "gco" = "git checkout";
      "gb" = "git branch";
      "glog" = "git log --oneline --decorate --graph";

      # Directory shortcuts
      "projects" = "cd ~/Projects";
      "github" = "cd ~/Projects/github.com";

      # Safety
      "rm" = "rm -i";
      "cp" = "cp -i";
      "mv" = "mv -i";

      # Reference aliases from kunchenguid (commented for documentation):
      # "cc" = "claude --dangerously-skip-permissions";
      # "co" = "codex --full-auto";
      # "m" = "git switch main";
    };

    # Additional shell configuration
    initExtra = ''
      # Starship prompt
      eval "$(starship init zsh)"

      # NVM configuration (shell-based, not via Nix)
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Auto-load .nvmrc if present
      autoload -U add-zsh-hook
      load-nvmrc() {
        local node_version="$(nvm version)"
        local nvmrc_path="$(nvm_find_nvmrc)"

        if [ -n "$nvmrc_path" ]; then
          local nvmrc_node_version=$(nvm version "$(cat "''${nvmrc_path}")")

          if [ "$nvmrc_node_version" = "N/A" ]; then
            nvm install
          elif [ "$nvmrc_node_version" != "$node_version" ]; then
            nvm use
          fi
        elif [ "$node_version" != "$(nvm version default)" ]; then
          nvm use default
        fi
      }
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

      # Homebrew path (for packages not in Nix)
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

      # gcloud SDK path (if installed via Homebrew)
      if [ -f "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc" ]; then
        source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
      fi
      if [ -f "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc" ]; then
        source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
      fi

      # kubectl completion
      command -v kubectl &> /dev/null && source <(kubectl completion zsh)

      # Colima Docker configuration
      export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

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

      # Work profile functions (explicit loading, never auto-load)
      work-a() {
        export AWS_PROFILE=company-a
        export GCP_PROJECT=company-a-project
        export SSH_AUTH_SOCK=~/.ssh/company-a-agent.sock
        echo "✓ Company A environment loaded"
      }

      work-b() {
        export AWS_PROFILE=company-b
        export GCP_PROJECT=company-b-project
        export SSH_AUTH_SOCK=~/.ssh/company-b-agent.sock
        echo "✓ Company B environment loaded"
      }

      work-clear() {
        unset AWS_PROFILE GCP_PROJECT SSH_AUTH_SOCK
        echo "✓ Work environments cleared"
      }

      # Helper function for sorting JSON
      sort_json() {
        jq -S '.' "$1"
      }
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

      # Multi-company work profile support via includeIf
      # Automatically switches git config based on directory
      includeIf."gitdir:~/work/company-a/".path = "~/.gitconfig-company-a";
      includeIf."gitdir:~/work/company-b/".path = "~/.gitconfig-company-b";
    };

    # Git aliases
    aliases = {
      st = "status";
      ci = "commit";
      br = "branch";
      co = "checkout";
      df = "diff";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
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

    # VSCode settings (NAVS plugins)
    "Library/Application Support/Code/User/settings.json".source = ../vscode/settings.json;
    "Library/Application Support/Code/User/keybindings.json".source = ../vscode/keybindings.json;

    # Claude settings and skills
    ".claude/settings.json".source = ../claude/settings.json;
    ".claude/keybindings.json".source = ../claude/keybindings.json;
    ".claude/skills".source = ../claude/skills;

    # Global AGENTS.md (shared instructions for all AI assistants)
    ".claude/CLAUDE.md".source = ../home/AGENTS.md;
    ".codex/AGENTS.md".source = ../home/AGENTS.md;
    ".config/opencode/AGENTS.md".source = ../home/AGENTS.md;

    # SSH config - generic host aliases only
    # For host-specific settings, use ~/.ssh/config.local (not tracked)
    ".ssh/config".source = ../.ssh/config;

    # Git configuration examples (user creates .gitconfig.local)
    ".gitconfig.local.example".source = ../.gitconfig.local.example;
  };
}
