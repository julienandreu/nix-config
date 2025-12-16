{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    jq
    zoxide
    nixfmt-rfc-style # Nix formatter (RFC-style formatting)
    # gix # Blazing fast Rust-based git implementation (gitoxide) - package name may differ
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
