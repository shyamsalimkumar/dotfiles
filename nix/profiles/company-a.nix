{ pkgs, ... }:

{
  # Company A work profile
  # Enable this profile by creating ~/.config/nix-darwin/local.nix with:
  # { profiles.companyA.enable = true; }

  # Company-specific packages
  # home.packages = with pkgs; [
  #   # Company A specific tools
  #   # Example: terraform, kubectl, helm, etc.
  # ];

  # Company-specific git configuration
  # This is loaded automatically via gitconfig includeIf when in ~/work/company-a/
  home.file.".gitconfig-company-a".text = ''
    [user]
        name = Your Name
        email = you@company-a.com

    [core]
        sshCommand = ssh -i ~/.ssh/company-a_rsa
  '';

  # Company-specific aliases
  programs.zsh.shellAliases = {
    # Example: company-a specific shortcuts
    # "ssh-a" = "ssh -i ~/.ssh/company-a_rsa";
  };

  # Note: Environment variables should be loaded explicitly via work-a() function
  # defined in home.nix, not auto-loaded. This prevents credential leakage.
}
