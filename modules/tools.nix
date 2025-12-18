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
  # Theme is configured via catppuccin.bat module in theme.nix
  programs.bat = {
    enable = true;
    config = {
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
    # Eza aliases
    ll = "eza -lah";

    # Vim aliases
    vim = "nvim";
  };

  # FZF
  # Theme is configured via catppuccin.fzf module in theme.nix
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height 40%"
      "--border"
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
        {
          # Profile name
          name = "Default profile";
          selected = true;

          # Device-specific configuration for Planck EZ Glow (ZSA Technology Labs)
          devices = [
            {
              identifiers = {
                vendor_id = 12951;  # 0x3297
                product_id = 50895; # 0xc6cf
                is_keyboard = true;
                is_pointing_device = false;
              };
              # Modify events: enabled
              modify_events = true;
              # Disable the built-in keyboard while this device is connected: enabled
              disable_built_in_keyboard_if_exists = true;
              # Manipulate caps lock LED: enabled
              manipulate_caps_lock_led = true;
              # Ignore vendor events: disabled (not recommended for non-Apple devices, but as per user config)
              ignore_vendor_events = false;
            }
          ];

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
