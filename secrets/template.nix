# secrets/template.nix
# Copy this file to ~/.config/nix-config/local/secrets.nix and fill in your values
# This file should NOT be committed to git (it's in .gitignore)

# This file is imported by home.nix if it exists
# It allows you to set user-specific values without modifying the main config

{ config, pkgs, ... }:

{
  # Override git configuration with your personal details
  programs.git.settings.user = {
    name = "Your Name";
    email = "your.email@example.com";
  };

  # You can add other personal overrides here
  # For example:
  # home.packages = with pkgs; [ your-personal-tools ];
}
