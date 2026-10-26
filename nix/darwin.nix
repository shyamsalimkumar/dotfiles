{ lib, user, ... }:

let
  # Needs --impure (see nix/rebuild.sh): these files live outside the flake,
  # and pure evaluation silently treats them as missing.
  stateDir = "/Users/${user}/.config/dotfiles";
  readList = file:
    lib.filter (cask: cask != "")
      (map (line: lib.trim (lib.head (lib.splitString "#" line)))
        (lib.splitString "\n" (builtins.readFile file)));
  isWork = builtins.pathExists "${stateDir}/machine"
    && lib.trim (builtins.readFile "${stateDir}/machine") == "work";
  optionalCasks =
    if !isWork then readList ./optional-casks.txt
    else if builtins.pathExists "${stateDir}/optional-casks" then readList "${stateDir}/optional-casks"
    else [ ];
in
{
  # Nix is installed and managed by Determinate (see nix/bootstrap.sh), not nix-darwin.
  # nix.settings below has no effect while this is false, but Determinate already
  # configures flakes and trusted users on its own.
  nix.enable = false;

  # Allow unfree packages (needed for some applications)
  nixpkgs.config.allowUnfree = true;

  # Required by nix-darwin: user-scoped options (homebrew, system.defaults) apply to this user
  system.primaryUser = user;

  # macOS system defaults (adopted from reference)
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      _HIHideMenuBar = true;
      AppleShowAllExtensions = true;
    };
    dock = {
      autohide = true;
    };
    finder = {
      FXPreferredViewStyle = "Nlsv";
      CreateDesktop = false;
    };
    trackpad = {
      Clicking = true;
    };
  };

  # Homebrew configuration
  # Used only for packages not available in nixpkgs
  homebrew = {
    enable = true;

    # Cleanup strategy
    # Current: "uninstall" (safe during migration - only removes undeclared packages)
    # Future: "zap" (strict declarative mode - removes all undeclared packages and data)
    onActivation.cleanup = "uninstall";

    # Custom taps
    taps = [
      "derailed/k9s"
      "homeport/tap"
    ];

    # Homebrew packages (formulae) not available in nixpkgs
    brews = [
      # Version managers (shell-based, not suitable for Nix)
      "pyenv"

      # Tools not in nixpkgs
      "transcrypt"  # Git encryption
      "trurl"       # URL tool

      # macOS-specific formulae
      "colima"      # Docker runtime for macOS (started on first docker call, see the shims in nix/home.nix)
      "dockutil"    # Dock management
    ];

    # macOS Applications (Casks). These are always installed; the rest live in
    # optional-casks.txt so work machines can pick which of them to install.
    casks = [
      # Development Tools
      "visual-studio-code"
      # Note: wezterm IS in nixpkgs, but using cask for now for consistency
      "wezterm"
      # Note: Xcode has no cask and can't be installed via Nix either - Apple
      # only distributes it via the App Store or developer.apple.com, and
      # doesn't allow third-party redistribution. scripts/post-install.sh
      # checks for it and warns if missing instead of trying to install it.
      # "ghostpepper"     # Speech-to-text/meeting transcription (https://github.com/matthartman/ghost-pepper)
                          # - not installed automatically, uncomment to enable

      # Fonts
      "font-hack-nerd-font"
    ] ++ map (cask:
      # Only ollama-app's bundled CLI is used (launchd.user.agents.ollama below);
      # don't open the app, it starts a second server. Unlike nixpkgs' build and
      # the ollama formula, it ships MLX with xgrammar, so Mac models and JSON
      # output work. greedy: brew skips auto-updating casks otherwise, and the
      # app never runs.
      if cask == "ollama-app" then { name = cask; greedy = true; } else cask
    ) optionalCasks;
  };

  # Ollama server for Pi and Snaply (the Linux equivalent is services.ollama in
  # home.nix). The default 4K context silently truncates meeting transcripts.
  launchd.user.agents.ollama = lib.mkIf (lib.elem "ollama-app" optionalCasks) {
    serviceConfig = {
      ProgramArguments = [ "/Applications/Ollama.app/Contents/Resources/ollama" "serve" ];
      EnvironmentVariables.OLLAMA_CONTEXT_LENGTH = "32768";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${user}/Library/Logs/ollama.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/ollama.log";
    };
  };

  # Used for backwards compatibility
  system.stateVersion = 4;

  # Platform-specific
  nixpkgs.hostPlatform = "aarch64-darwin";
}
