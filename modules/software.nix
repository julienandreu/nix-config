{ pkgs, lib, catppuccinFlavor, ... }:

{
  home.packages = with pkgs; [
    # Development tools
    docker-compose
    terraform
# AI coding assistants
# Anthropic's agentic coding tool
claude-code codex # OpenAI's lightweight coding agent

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

      # Color settings
      color.ui = "auto";
    };
    # Catppuccin theme for delta is configured via catppuccin.delta module in theme.nix
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

  # Cursor Editor configuration - hybrid approach (Option 2)
  # Nix manages defaults that can be overridden by user settings
  # Path: ~/Library/Application Support/Cursor/User/settings.json.defaults
  # The merge script (scripts/merge-cursor-settings.sh) merges defaults with user settings
  # User can freely edit settings.json - their changes will be preserved
  home.file."Library/Application Support/Cursor/User/settings.json.defaults" = {
    text = builtins.toJSON ({
      # Catppuccin Theme
      # Requires extensions: Catppuccin.catppuccin-vsc + Catppuccin.catppuccin-vsc-icons
      # Theme names: "Catppuccin Latte", "Catppuccin Frappé", "Catppuccin Macchiato", "Catppuccin Mocha"
      "workbench.colorTheme" =
        if catppuccinFlavor == "latte" then "Catppuccin Latte"
        else if catppuccinFlavor == "frappe" then "Catppuccin Frappé"
        else if catppuccinFlavor == "macchiato" then "Catppuccin Macchiato"
        else "Catppuccin Mocha";
      "workbench.iconTheme" = "catppuccin-${catppuccinFlavor}";

      # Font settings
      "terminal.integrated.fontFamily" = "'MesloLGL Nerd Font Mono', 'FiraCode Nerd Font Mono', 'Fira Code'";
      "terminal.integrated.fontSize" = 12;
      "terminal.integrated.fontLigatures" = true;

      "editor.fontFamily" = "'MesloLGL Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
      "editor.fontSize" = 12;
      "editor.fontLigatures" = true;

      # Minimap settings
      "editor.minimap.enabled" = true;

      # Editor settings from colleague's configuration
      "editor.codeActionsOnSave" = {
        "source.fixAll.eslint" = "explicit";
      };
      "editor.formatOnSave" = true;
      "editor.formatOnSaveMode" = "modifications";
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;

      # JSON settings
      "[json]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.quickSuggestions" = {
          "strings" = true;
        };
        "editor.suggest.insertMode" = "replace";
      };

      # Markdown settings
      "[markdown]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.unicodeHighlight.ambiguousCharacters" = false;
        "editor.unicodeHighlight.invisibleCharacters" = false;
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.wordWrap" = "on";
        "editor.quickSuggestions" = {
          "comments" = "off";
          "strings" = "off";
          "other" = "off";
        };
      };

      # TypeScript settings
      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      # Python settings
      "[python]" = {
        "editor.defaultFormatter" = "charliermarsh.ruff";
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "explicit";
          "source.organizeImports" = "explicit";
        };
      };

      # Rust settings
      "[rust]" = {
        "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        "editor.formatOnSave" = true;
      };

      # Terraform settings
      "[terraform]" = {
        "editor.defaultFormatter" = "hashicorp.terraform";
        "editor.formatOnSave" = true;
      };
      "[terraform-vars]" = {
        "editor.defaultFormatter" = "hashicorp.terraform";
        "editor.formatOnSave" = true;
      };

      # Nix settings
      "[nix]" = {
        "editor.formatOnSave" = true;
      };

      # YAML settings
      "[yaml]" = {
        "editor.defaultFormatter" = "redhat.vscode-yaml";
        "editor.formatOnSave" = true;
      };

      # TOML settings
      "[toml]" = {
        "editor.defaultFormatter" = "tamasfe.even-better-toml";
        "editor.formatOnSave" = true;
      };
    });
  };

  # Merge Cursor settings on activation: combine Nix defaults with user overrides
  # This allows users to edit settings.json freely while keeping Nix-managed defaults
  home.activation.mergeCursorSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
    DEFAULTS_FILE="$CURSOR_USER_DIR/settings.json.defaults"
    SETTINGS_FILE="$CURSOR_USER_DIR/settings.json"

    # Ensure directory exists
    mkdir -p "$CURSOR_USER_DIR"

    # If defaults don't exist yet, skip (first run)
    if [ ! -f "$DEFAULTS_FILE" ]; then
      exit 0
    fi

    # If settings.json doesn't exist, copy defaults
    if [ ! -f "$SETTINGS_FILE" ]; then
      cp "$DEFAULTS_FILE" "$SETTINGS_FILE"
      echo "Created Cursor settings.json from Nix defaults"
      exit 0
    fi

    # Merge: user settings override defaults (using jq)
    # Deep merge where user values take precedence
    if command -v jq >/dev/null 2>&1; then
      MERGED=$(jq -s '.[0] * .[1]' "$DEFAULTS_FILE" "$SETTINGS_FILE" 2>/dev/null)
      if [ $? -eq 0 ] && [ -n "$MERGED" ]; then
        # Only update if there are changes (macOS-compatible hash)
        if command -v md5sum >/dev/null 2>&1; then
          HASH_CMD="md5sum"
          HASH_CUT="cut -d' ' -f1"
        elif command -v md5 >/dev/null 2>&1; then
          HASH_CMD="md5"
          HASH_CUT="cut -d' ' -f4"
        else
          HASH_CMD=""
        fi

        if [ -n "$HASH_CMD" ]; then
          CURRENT_HASH=$(jq -c . "$SETTINGS_FILE" | $HASH_CMD | $HASH_CUT)
          MERGED_HASH=$(echo "$MERGED" | jq -c . | $HASH_CMD | $HASH_CUT)

          if [ "$CURRENT_HASH" != "$MERGED_HASH" ]; then
            cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
            echo "$MERGED" | jq . > "$SETTINGS_FILE"
            echo "Merged Nix defaults with user Cursor settings"
          fi
        else
          # Fallback: always merge if hash command not available
          cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
          echo "$MERGED" | jq . > "$SETTINGS_FILE"
          echo "Merged Nix defaults with user Cursor settings"
        fi
      fi
    else
      echo "Warning: jq not found, skipping Cursor settings merge"
    fi
  '';
}
