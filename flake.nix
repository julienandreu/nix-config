{
  description = "Personal Nix Configuration for macOS";

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

    # Catppuccin theming
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      catppuccin,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "julien";
      homeDirectory = "/Users/${username}";

      # pkgs for non-darwin outputs (formatter, standalone HM)
      pkgsFor = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.mac = darwin.lib.darwinSystem {
        inherit system;

        # Make username/catppuccin available to darwin + HM modules
        specialArgs = { inherit username homeDirectory catppuccin; };

        modules = [
          # nixpkgs config the nix-darwin way
          (
            { ... }:
            {
              nixpkgs = {
                hostPlatform = system;
                config.allowUnfree = true;
              };
            }
          )

          ./machines/default.nix

          home-manager.darwinModules.home-manager
          (
            { lib, ... }:
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = { inherit username homeDirectory catppuccin; };

              # IMPORTANT: don't use $USER/env here
              home-manager.users.${username} = {
                imports = [ ./home.nix ];
                home.homeDirectory = lib.mkForce homeDirectory;
              };
            }
          )
        ];
      };

      # Standalone home-manager configuration (optional)
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor;
        extraSpecialArgs = { inherit username homeDirectory catppuccin; };
        modules = [ ./home.nix ];
      };

      formatter.${system} = pkgsFor.nixfmt-tree;
    };
}
