{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Terminal
    ghostty

    # Development tools
    docker-compose

    # GUI Applications (Cursor, Slack, Linear, Docker, Karabiner)
    # are managed via nix-darwin's homebrew module in machines/default.nix
  ];

  # Git configuration
  # User-specific values should be set in ~/.config/nix-config/local/secrets.nix
  # This file is automatically imported if it exists (see home.nix)
  programs.git = {
    enable = true;
    # Default values - will be overridden by local/secrets.nix if it exists
    # Users should create ~/.config/nix-config/local/secrets.nix from secrets/template.nix
    userName = ""; # Set in local/secrets.nix
    userEmail = ""; # Set in local/secrets.nix

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";

      # Performance optimizations for faster git operations
      # Enable filesystem monitor for faster status (macOS)
      core.fsmonitor = true;
      # Use more efficient diff algorithm
      diff.algorithm = "histogram";
      # Faster status with untracked files
      status.showUntrackedFiles = "normal";
      # Use faster index format
      index.version = 4;
      # Optimize for large repos
      feature.manyFiles = true;
      # Faster log operations
      log.decorate = "short";
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };

  # AWS CLI
  programs.awscli = {
    enable = true;
    # Credentials will be configured separately per user via aws configure
  };

  # Ghostty configuration - inlined in Nix
  home.file.".config/ghostty/config".text = ''
    # Ghostty Configuration with Catppuccin Mocha Theme

    # Theme
    theme = catppuccin-mocha

    # Font
    font-family = GeistMono Nerd Font Mono
    font-size = 14

    # Window
    window-padding-x = 10
    window-padding-y = 10
    window-theme = dark

    # Cursor
    cursor-style = block
    cursor-style-blink = true

    # Shell
    shell-integration = zsh

    # Colors (Catppuccin Mocha)
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    cursor = "#f5e0dc"
    selection-background = "#313244"
    color0 = "#45475a"
    color1 = "#f38ba8"
    color2 = "#a6e3a1"
    color3 = "#f9e2af"
    color4 = "#89b4fa"
    color5 = "#f5c2e7"
    color6 = "#94e2d5"
    color7 = "#bac2de"
    color8 = "#585b70"
    color9 = "#f38ba8"
    color10 = "#a6e3a1"
    color11 = "#f9e2af"
    color12 = "#89b4fa"
    color13 = "#f5c2e7"
    color14 = "#94e2d5"
    color15 = "#a6adc8"
  '';
}
