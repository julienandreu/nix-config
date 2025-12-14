{
  description = "Company Engineering Workstation Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For Catppuccin theming
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, home-manager, darwin, catppuccin, ... }:
    let
      system = "aarch64-darwin"; # Change to x86_64-darwin for Intel Macs
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # For cursor, etc.
      };
    in
    {
      # For macOS systems using nix-darwin
      darwinConfigurations = {
        macbook = darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./machines/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${builtins.getEnv "USER"} = import ./home.nix;
              home-manager.extraSpecialArgs = { inherit catppuccin; };
            }
          ];
        };
      };

      # Standalone home-manager configuration (if not using nix-darwin)
      homeConfigurations = {
        "${builtins.getEnv "USER"}" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
          ];
          extraSpecialArgs = { inherit catppuccin; };
        };
      };

      # Formatter for Nix files (enables `nix fmt` command)
      # Uses nixfmt-tree which wraps nixfmt-rfc-style for project-wide formatting
      formatter.${system} = pkgs.nixfmt-tree;
    };
}

