{ pkgs, username, ... }:

{
  system.primaryUser = username;

  # ghostty is not available for macOS, only Linux
  # environment.systemPackages = with pkgs; [
  #   ghostty
  # ];

  programs.zsh.enable = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    casks = [
      "google-chrome"
      "cursor"
      "slack"
      "linear-linear"
      "docker-desktop"
      "karabiner-elements"
    ];
  };

  nix.settings = {
    trusted-users = [
      "root"
      username
      "@admin"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = 5;
}
