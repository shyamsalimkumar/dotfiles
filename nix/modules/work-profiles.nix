{ config, lib, pkgs, user, ... }:

with lib;

let
  cfg = config.profiles;
in
{
  # Import local configuration if it exists (gitignored)
  # This file allows enabling/disabling profiles without committing changes
  imports =
    let
      localConfigPath = "/Users/${user}/.config/nix-darwin/local.nix";
    in
    lib.optional (builtins.pathExists localConfigPath) localConfigPath;

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
      home-manager.users.${user} = import ../profiles/company-a.nix;
    })

    # Company B profile
    (mkIf cfg.companyB.enable {
      # Import Company B specific configuration
      home-manager.users.${user} = import ../profiles/company-b.nix;
    })
  ];
}
