{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development tools
    docker-compose
  ];

  # Git configuration
  # User-specific values should be set in:
  #   ~/.config/nix-config/local/secrets.nix
  programs.git = {
    enable = true;

    # Don't set empty values by default—let secrets.nix define these.
    # userName = "...";
    # userEmail = "...";

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";

      core.fsmonitor = true;
      diff.algorithm = "histogram";
      status.showUntrackedFiles = "normal";
      index.version = 4;
      feature.manyFiles = true;
      log.decorate = "short";

      aliases = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };

  programs.awscli = {
    enable = true;
  };

  # Ghostty configuration - inlined in Nix
  xdg.configFile."ghostty/config".text = ''
    # Ghostty Configuration with Catppuccin Mocha Theme

    theme = catppuccin-mocha

    font-family = MesloLGL Nerd Font Mono
    font-size = 12
    font-feature = calt
    font-feature = liga

    window-padding-x = 10
    window-padding-y = 10
    window-theme = dark

    cursor-style = block
    cursor-style-blink = true

    shell-integration = zsh

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

  # Cursor Editor configuration - inlined in Nix
  # Cursor uses VS Code's settings.json format
  # Path: ~/Library/Application Support/Cursor/User/settings.json
  home.file."Library/Application Support/Cursor/User/settings.json" = {
    force = true;
    text = builtins.toJSON {
      "editor.fontFamily" = "'MesloLGL Nerd Font Mono', 'MesloLGS Nerd Font Mono', 'MesloLGM Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
      "editor.fontSize" = 12;
      "editor.fontLigatures" = true;
    };
  };
}
