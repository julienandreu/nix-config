{ pkgs, lib, ... }:

{
  # Install nerd fonts
  # On macOS, home-manager installs fonts to ~/Library/Fonts/
  home.packages = with pkgs; [
    nerd-fonts.meslo-lg # Primary font used in Ghostty and Cursor config
  ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Performance: reduce timeouts for snappier prompt
      command_timeout = 200; # Max time for each module (ms)
      scan_timeout = 10; # Max time for directory scan (ms)

      format = "[ ](surface0)$os$username[](bg:surface0 fg:base)$directory[](fg:base bg:green)$git_branch$git_status[](fg:green bg:teal)$nodejs$rust$python$golang[](fg:teal bg:peach)$time[](fg:peach bg:crust)$cmd_duration[](fg:crust)$line_break$character";

      palette = "catppuccin_mocha";

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        orange = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };

      os = {
        disabled = false;
        style = "bg:surface0 fg:text";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:surface0 fg:text";
        style_root = "bg:surface0 fg:text";
        format = "[ $user ]($style)";
      };

      directory = {
        style = "fg:text bg:base";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol $branch ](fg:base bg:green)]($style)";
      };

      git_status = {
        style = "bg:teal";
        format = "[[($all_status$ahead_behind )](fg:base bg:green)]($style)";
        # Performance: skip submodule status checks
        ignore_submodules = true;
      };


      # === Language modules ===
      # Performance: only detect when relevant files present
      # Each module spawns a process to check version

      nodejs = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [ "package.json" ".nvmrc" ".node-version" ];
        detect_folders = [ "node_modules" ];
      };

      rust = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [ "Cargo.toml" ];
      };

      python = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [ "pyproject.toml" "requirements.txt" "setup.py" ".python-version" ];
      };

      golang = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [ "go.mod" ];
      };

      # Disabled for performance - uncomment if needed
      c.disabled = true;
      php.disabled = true;
      java.disabled = true;
      kotlin.disabled = true;
      haskell.disabled = true;

      docker_context = {
        symbol = "";
        style = "bg:mantle";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:peach";
        format = "[[  $time ](fg:mantle bg:peach)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:green)";
        error_symbol = "[](bold fg:red)";
        vimcmd_symbol = "[](bold fg:creen)";
        vimcmd_replace_one_symbol = "[](bold fg:purple)";
        vimcmd_replace_symbol = "[](bold fg:purple)";
        vimcmd_visual_symbol = "[](bold fg:lavender)";
      };

      cmd_duration = {
        disabled = false;
        show_milliseconds = false;
        style = "bg:crust";
        format = "[[  $duration ](fg:overlay0 bg:crust)]($style)";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Enable completions (loads completion definitions from packages)
    enableCompletion = true;

    # Lazy-load completions: defer compinit until first TAB press
    # This saves ~300-400ms on shell startup by not initializing
    # the completion system until it's actually needed.
    # See: https://scottspence.com/posts/speeding-up-my-zsh-shell
    completionInit = ''
      autoload -Uz compinit

      # Cache directory for zsh completions
      ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      mkdir -p "$ZSH_CACHE_DIR"

      # Lazy-load completions on first TAB press
      # This defers ~300-400ms of startup cost to first completion use
      function _lazy_compinit() {
        unfunction _lazy_compinit
        _comp_dump="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"

        # Use cached dump if less than 24 hours old, otherwise regenerate
        if [[ -f "$_comp_dump" && $(date +'%j') == $(date -r "$_comp_dump" +'%j' 2>/dev/null) ]]; then
          compinit -C -d "$_comp_dump"
        else
          compinit -d "$_comp_dump"
          touch "$_comp_dump"
        fi
        unset _comp_dump

        # Execute the actual completion after loading
        zle expand-or-complete
      }

      # Bind TAB to lazy compinit (will self-replace after first use)
      zle -N expand-or-complete _lazy_compinit
    '';

    initContent = ''
      # Fix for Ghostty compatibility - some tools don't recognize xterm-ghostty
      # See: https://www.bitdoze.com/starship-ghostty-terminal/
      export TERM=xterm-256color

      # Add Cursor CLI to PATH (installed via Homebrew cask)
      export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"

      # fnm (Fast Node Manager) - ~2ms init vs nvm's ~300ms
      # Supports .nvmrc and .node-version for automatic version switching
      eval "$(fnm env --use-on-cd --shell zsh)"

      eval "$(zoxide init zsh)"
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  programs.bat.enable = true;

  catppuccin.bat = {
    enable = true;
    flavor = "mocha";
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  # Ghostty terminal configuration
  # See: https://www.bitdoze.com/starship-ghostty-terminal/
  home.file.".config/ghostty/config".text = ''
    # Font settings
    font-family = MesloLGS Nerd Font Mono
    font-size = 12

    # Shell integration
    shell-integration = zsh

    # macOS specific
    macos-option-as-alt = true
  '';
}
