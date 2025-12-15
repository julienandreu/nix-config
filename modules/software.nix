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

  # Cursor Editor configuration - inlined in Nix
  # Cursor uses VS Code's settings.json format
  # Path: ~/Library/Application Support/Cursor/User/settings.json
  home.file."Library/Application Support/Cursor/User/settings.json" = {
    force = true;
    text = builtins.toJSON {
      # Catppuccin Mocha Theme
      # Requires extensions: Catppuccin.catppuccin-vsc + Catppuccin.catppuccin-vsc-icons
      "workbench.colorTheme" = "Catppuccin Mocha";
      "workbench.iconTheme" = "catppuccin-mocha";

      # Font settings
      "terminal.integrated.fontFamily" = "'MesloLGL Nerd Font Mono', 'FiraCode Nerd Font Mono', 'Fira Code'";
      "terminal.integrated.fontSize" = 12;
      "terminal.integrated.fontLigatures" = true;

      "editor.fontFamily" = "'MesloLGL Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
      "editor.fontSize" = 12;
      "editor.fontLigatures" = true;
    };
  };
}
