{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ===== Core Search & Navigation (already had) =====
    ripgrep # grep replacement - fast recursive search
    fd # find replacement - intuitive file finding
    fzf # fuzzy finder
    jq # JSON processor
    zoxide # smarter cd with frecency
    nixfmt-rfc-style # Nix formatter (RFC-style formatting)

    # ===== Rust-based CLI Alternatives =====
    # See: https://dev.to/lingodotdev/27-rust-based-alternatives-to-classic-cli-apps-2350
    # Some tools (bat, eza, bottom, tealdeer) are configured via programs.* below

    # File viewing & manipulation
    dust # du replacement - visual disk usage with bars
    sd # sed replacement - simpler find & replace syntax

    # Process & system monitoring
    procs # ps replacement - colored process tables

    # Development tools
    delta # diff replacement - syntax-highlighted diffs (configured as git pager)
    just # make replacement - simple command runner
    hyperfine # time replacement - statistical benchmarking

    # HTTP & networking
    xh # curl alternative - friendlier HTTP requests
  ];

  # Neovim with lazy.nvim plugin manager
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Copy entire nvim config directory (includes lazy.nvim setup and all plugins)
    # Plugins will be automatically installed by lazy.nvim on first launch
    extraLuaConfig = ''
      -- Config is loaded from ~/.config/nvim/init.lua
      -- which loads the config module structure
    '';
  };

  # Copy nvim config directory (includes all lua modules and lazy.nvim config)
  home.file.".config/nvim" = {
    source = ../configs/nvim;
    recursive = true;
  };

  # Zoxide (smarter cd)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Eza (ls replacement)
  programs.eza = {
    enable = true;
    enableZshIntegration = true; # Adds aliases: ls, ll, la, lt, lla
    icons = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  # Bat (cat replacement)
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Mocha";
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  # Bottom (system monitor)
  programs.bottom = {
    enable = true;
  };

  # Tealdeer (tldr pages)
  programs.tealdeer = {
    enable = true;
    settings = {
      display = {
        compact = false;
        use_pager = true;
      };
      updates = {
        auto_update = true;
      };
    };
  };

  # Shell aliases for Rust CLI tools
  home.shellAliases = {
    # Bat aliases
    cat = "bat --paging=never";
    catp = "bat"; # cat with pager

    # Dust aliases
    du = "dust";
    dua = "dust -d 1"; # disk usage for current directory

    # Procs aliases
    ps = "procs";
    pst = "procs --tree"; # process tree

    # Other useful aliases
    find = "fd";
    grep = "rg";
    diff = "delta";
    top = "btm";
    bench = "hyperfine";
    http = "xh";

    # Eza aliases
    ls = "eza";
    ll = "ls -la";

    # Vim aliases
    vim = "nvim";
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    ];
  };

  # Karabiner-Elements configuration - inlined in Nix
  home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
    global = {
      check_for_updates_on_startup = true;
      show_in_menu_bar = true;
      show_profile_name_in_menu_bar = false;
    };
    profiles = [
        # Disable built-in keyboard when any external keyboard is connected
        {
          disable_built_in_keyboard_if_exists = true;
          devices = [ ];
          fn_function_keys = [ ];
          simple_modifications = [ ];
          virtual_hid_keyboard = {
            country_code = 0;
            keyboard_type_v2 = "ansi";
          };
        }
    ];
  };
}
