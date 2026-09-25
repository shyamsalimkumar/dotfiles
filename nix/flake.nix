{
  description = "shyamsalimkumar's cross-platform (macOS + Linux/WSL) system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager }:
    let
      user = "shyamsk";
    in
    {
      darwinConfigurations.mac = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin.nix
          ./modules/work-profiles.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user} = import ./home.nix;
            users.users.${user}.home = "/Users/${user}";
          }
        ];
        specialArgs = { inherit user; };
      };

      # Standalone home-manager config for native Linux and WSL2 distros.
      # WSL2 is just a Linux userland, so this one target covers both -
      # no nix-darwin equivalent is needed since we only manage the user's
      # home environment here, not a whole OS.
      # To add ARM Linux/WSL support later, turn this into a helper
      # function parameterized by `system` and call it for each system.
      homeConfigurations.linux = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ./home.nix
          {
            home.username = user;
            home.homeDirectory = "/home/${user}";
          }
        ];
      };
    };
}
