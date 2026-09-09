{ pkgs, ... }:

{
  # Company B work profile
  # Enable this profile by creating ~/.config/nix-darwin/local.nix with:
  # { profiles.companyB.enable = true; }

  # Company-specific packages
  # home.packages = with pkgs; [
  #   # Company B specific tools
  #   # Example: aws-vault, gcloud, etc.
  # ];

  # Company-specific git configuration
  # This is loaded automatically via gitconfig includeIf when in ~/work/company-b/
  home.file.".gitconfig-company-b".text = ''
    [user]
        name = Your Name
        email = you@company-b.com

    [core]
        sshCommand = ssh -i ~/.ssh/company-b_rsa
  '';

  # Company-specific aliases
  programs.zsh.shellAliases = {
    # Example: company-b specific shortcuts
    # "ssh-b" = "ssh -i ~/.ssh/company-b_rsa";
  };

  # Note: Environment variables should be loaded explicitly via work-b() function
  # defined in home.nix, not auto-loaded. This prevents credential leakage.
}
