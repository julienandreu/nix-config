{
  config,
  pkgs,
  catppuccin,
  ...
}:

{
  home.packages = with pkgs; [
    # Install Nerd Fonts (GeistMono)
    (nerdfonts.override { fonts = [ "GeistMono" ]; })
  ];

  # Font configuration
  fonts.fontconfig.enable = true;

  # Starship prompt - fully configured in Nix
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    # Performance optimizations
    settings = {
      command_timeout = 500;
      scan_timeout = 30;

      format = ''
        [  ](surface0)\
        $os\
        $username\
        [](bg:surface0 fg:base)\
        $directory\
        [](fg:base bg:green)\
        $git_branch\
        $git_status\
        [](fg:green bg:teal)\
        $c\
        $rust\
        $golang\
        $nodejs\
        $php\
        $java\
        $kotlin\
        $haskell\
        $python\
        [](fg:teal bg:peach)\
        $time\
        [](fg:peach bg:crust)\
        $cmd_duration\
        [](fg:crust)\
        $line_break$character
      '';

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
          Windows = "";
          Ubuntu = "";
          SUSE = "";
          Raspbian = "";
          Mint = "";
          Macos = "";
          Manjaro = "";
          Linux = "";
          Gentoo = "";
          Fedora = "";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "";
          Artix = "";
          CentOS = "";
          Debian = "";
          Redhat = "";
          RedHatEnterprise = "";
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
          Documents = " ";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
          Developer = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol $branch ](fg:base bg:green)]($style)";
        only_attached = false;
      };

      git_status = {
        style = "bg:teal";
        format = "[[($all_status$ahead_behind )](fg:base bg:green)]($style)";
        disabled = false;
        conflicted = "=";
        up_to_date = "";
        untracked = "?";
        ahead = "⇡${count}";
        behind = "⇣${count}";
        diverged = "⇕⇡${ahead_count}⇣${behind_count}";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      nodejs = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [ "package.json" ];
        detect_folders = [ "node_modules" ];
      };

      c = {
        symbol = " ";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "makefile"
          "Makefile"
          "CMakeLists.txt"
          ".clang-format"
        ];
        detect_extensions = [
          "c"
          "h"
        ];
      };

      rust = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "Cargo.toml"
          "Cargo.lock"
        ];
        detect_extensions = [ "rs" ];
      };

      golang = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "go.mod"
          "go.sum"
          "go.work"
        ];
        detect_folders = [ "vendor" ];
      };

      php = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "composer.json"
          "composer.lock"
        ];
      };

      java = {
        symbol = " ";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "pom.xml"
          "build.gradle"
          "build.gradle.kts"
          "settings.gradle"
          "settings.gradle.kts"
        ];
        detect_extensions = [
          "java"
          "class"
          "jar"
          "gradle"
        ];
      };

      kotlin = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "build.gradle.kts"
          "settings.gradle.kts"
        ];
        detect_extensions = [
          "kt"
          "kts"
        ];
      };

      haskell = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          "stack.yaml"
          "*.cabal"
        ];
        detect_extensions = [
          "hs"
          "lhs"
        ];
      };

      python = {
        symbol = "";
        style = "bg:teal";
        format = "[[ $symbol( $version) ](fg:base bg:teal)]($style)";
        detect_files = [
          ".python-version"
          "Pipfile"
          "__pyproject__.toml"
          "requirements.txt"
          "setup.py"
          "pyproject.toml"
          "pyrightconfig.json"
        ];
        detect_folders = [
          ".venv"
          ".virtualenv"
        ];
      };

      docker_context = {
        symbol = "";
        style = "bg:mantle";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:peach";
        format = "[[  $time ](fg:mantle bg:peach)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:green)";
        error_symbol = "[](bold fg:red)";
        vimcmd_symbol = "[](bold fg:green)";
        vimcmd_replace_one_symbol = "[](bold fg:purple)";
        vimcmd_replace_symbol = "[](bold fg:purple)";
        vimcmd_visual_symbol = "[](bold fg:lavender)";
      };

      cmd_duration = {
        disabled = false;
        min_time = 0;
        show_milliseconds = false;
        style = "bg:crust";
        format = "[[  $duration ](fg:overlay0 bg:crust)]($style)";
      };
    };
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -la";
      vim = "nvim";
      cat = "bat";
      ls = "eza";
    };

    initExtra = ''
      # Additional shell configuration
      eval "$(zoxide init zsh)"

      # FZF keybindings
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  # Bat (better cat) with Catppuccin theme
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin-mocha";
    };
    themes = {
      catppuccin-mocha = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-mocha.tmTheme";
      };
    };
  };

  # Eza (better ls)
  programs.eza = {
    enable = true;
    enableAliases = true;
    git = true;
    icons = true;
  };
}
