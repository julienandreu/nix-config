{ pkgs, lib, ... }:

{
  # Install all nerd fonts (or select specific ones like pkgs.nerd-fonts.FiraCode)
  # Filter out non-package attributes (like override functions)
  home.packages = lib.filter (pkg: lib.isDerivation pkg) (lib.attrValues pkgs.nerd-fonts);

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

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

      # (rest of your starship settings unchanged)
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
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      # … keep the rest as-is …
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:peach";
        format = "[[  $time ](fg:mantle bg:peach)]($style)";
      };

      line_break.disabled = false;

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

    initContent = ''
      # Add Cursor CLI to PATH (installed via Homebrew cask)
      export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"

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
}
