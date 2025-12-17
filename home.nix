{
  config,
  pkgs,
  lib,
  username,
  homeDirectory,
  catppuccin,
  catppuccinFlavor,
  ...
}:

let
  # setup.sh writes here:
  localSecretsPath = "${homeDirectory}/.config/nix-config/local/secrets.nix";
  hasLocalSecrets = builtins.pathExists localSecretsPath;
in
{
  imports = [
    catppuccin.homeModules.catppuccin
    ./modules/software.nix
    ./modules/languages.nix
    ./modules/tools.nix
    ./modules/theme.nix
  ]
  ++ lib.optionals hasLocalSecrets [ localSecretsPath ];

  home.username = username;
  # home.homeDirectory is set in flake.nix to avoid conflicts

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
