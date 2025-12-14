{ config, pkgs, catppuccin, ... }:

let
  # Try to import local secrets file if it exists
  # This allows users to override settings without modifying the main config
  localSecrets = builtins.pathExists "${config.home.homeDirectory}/.config/nix-config/local/secrets.nix";
in

{
  imports = [
    ./modules/software.nix
    ./modules/languages.nix
    ./modules/tools.nix
    ./modules/theme.nix
  ] ++ (if localSecrets then [
    "${config.home.homeDirectory}/.config/nix-config/local/secrets.nix"
  ] else []);

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your configuration is
  # compatible with. Don't change this unless you know what you're doing.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}

