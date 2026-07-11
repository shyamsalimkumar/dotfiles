{ pkgs, user, ... }:

{
  # Nix configuration
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [ user ];
  };

  # Allow unfree packages (needed for some applications)
  nixpkgs.config.allowUnfree = true;

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
      "theboredteam/boring-notch"
    ];

    # Homebrew packages (formulae) not available in nixpkgs
    brews = [
      # Version managers (shell-based, not suitable for Nix)
      "pyenv"

      # Tools not in nixpkgs
      "transcrypt"  # Git encryption
      "trurl"       # URL tool

      # macOS-specific formulae
      "colima"      # Docker runtime for macOS
      "dockutil"    # Dock management
    ];

    # macOS Applications (Casks)
    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"

      # Development Tools
      "visual-studio-code"
      "iterm2"
      # Note: wezterm IS in nixpkgs, but using cask for now for consistency
      "wezterm"
      "meld"              # Visual diff tool
      "claude-code"       # AI coding assistant

      # Cloud & DevOps
      "google-cloud-cli"  # gcloud CLI (formerly gcloud-sdk)

      # Productivity
      "slack"             # Team communication
      "caffeine"          # Prevent sleep
      "boring-notch"      # Dynamic Island for macOS

      # Utilities
      "google-chrome"     # Web browser
      "basictex"          # Minimal TeX distribution
      "opensuperwhisper"  # Speech recognition

      # Fonts
      "font-hack-nerd-font"
    ];
  };

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 4;

  # Platform-specific
  nixpkgs.hostPlatform = "aarch64-darwin";
}
