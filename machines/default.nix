{ pkgs, ... }:

{
  # System-level packages (installed system-wide)
  # Note: Docker and Karabiner are now managed via Homebrew casks below
  environment.systemPackages = with pkgs; [
    ghostty
  ];

  # Enable Zsh as the default shell
  programs.zsh.enable = true;

  # Enable Docker service
  services.docker.enable = true;

  # Homebrew integration for apps not available in nixpkgs
  # nix-darwin's homebrew module allows declarative management of Homebrew casks
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    # Install GUI applications via Homebrew cask
    # These apps are not yet available in nixpkgs
    casks = [
      "cursor"
      "slack"
      "linear"
      "docker"
      "karabiner-elements"
    ];
  };

  # Nix settings
  nix.settings.trusted-users = [ "@admin" ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # System version
  system.stateVersion = 5;
}
