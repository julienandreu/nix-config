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

      # ===== Performance Optimizations =====
      # See: https://www.git-tower.com/blog/git-performance/
      # See: https://stackoverflow.com/questions/4994772/ways-to-improve-git-status-performance

      # Working tree performance
      core.fsmonitor = true; # Built-in file system monitor (Git 2.37+)
      core.untrackedCache = true; # Cache untracked file searches
      core.preloadIndex = true; # Parallel index loading
      feature.manyFiles = true; # Optimizations for large repos (enables index v4 + untrackedCache)
      index.version = 4; # Smaller index format (30-50% reduction)

      # History performance
      core.commitGraph = true; # Use commit graph for faster history
      fetch.writeCommitGraph = true; # Update commit graph on fetch
      gc.writeCommitGraph = true; # Update commit graph on gc

      # Pack/compression performance
      pack.threads = 0; # Use all CPU cores for packing

      # Optional: Skip expensive checks (uncomment if needed)
      # status.aheadBehind = false;  # Skip ahead/behind calculation with remote
      # diff.ignoreSubmodules = "dirty";  # Skip checking submodule working trees

      # Diff settings
      diff.algorithm = "histogram";
      status.showUntrackedFiles = "normal";
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

  # SSH configuration with connection sharing for faster Git operations
  # See: http://interrobeng.com/2013/08/25/speed-up-git-5x-to-50x/
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Host-specific settings
    matchBlocks = {
      # Default settings for all hosts
      "*" = {
        # Disable default config - we define everything explicitly
        addKeysToAgent = "yes";

        # Connection sharing: reuse SSH connections (5x faster Git operations)
        controlMaster = "auto";
        controlPath = "/tmp/ssh-%r@%h:%p";
        controlPersist = "10m"; # Keep connection open for 10 minutes

        # Compression for slower connections
        compression = true;

        # Keep connections alive
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_github"; # Created by onboard.sh
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_gitlab"; # Optional: create manually if needed
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
