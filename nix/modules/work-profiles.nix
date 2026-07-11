{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.profiles;
in
{
  # Import local configuration if it exists (gitignored)
  # This file allows enabling/disabling profiles without committing changes
  imports = [
    (mkIf (builtins.pathExists ~/.config/nix-darwin/local.nix)
      ~/.config/nix-darwin/local.nix)
  ];

  options.profiles = {
    companyA = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Company A work profile";
      };
    };

    companyB = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Company B work profile";
      };
    };
  };

  config = mkMerge [
    # Company A profile
    (mkIf cfg.companyA.enable {
      # Import Company A specific configuration
      home-manager.users.${config.user} = import ../profiles/company-a.nix;
    })

    # Company B profile
    (mkIf cfg.companyB.enable {
      # Import Company B specific configuration
      home-manager.users.${config.user} = import ../profiles/company-b.nix;
    })
  ];
}
