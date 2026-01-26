{ pkgs, username, ... }:

{
  # Set primary user - username comes from specialArgs in flake.nix
  system.primaryUser = username;

  programs.zsh.enable = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      "oneleet/tap"
    ];

    brews = [
      "displayplacer" # CLI tool to configure display resolutions
    ];

    casks = [
      "1password"
      "cursor"
      "docker-desktop"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "linear-linear"
      "oneleet-agent"
      "slack"
    ];
  };

  nix.settings = {
    trusted-users = [
      "root"
      username
      "@admin"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # ==========================================================================
  # macOS System Preferences
  # ==========================================================================

  system.defaults = {
    # Keyboard settings
    NSGlobalDomain = {
      # Use F1, F2, etc. keys as standard function keys
      # (hold Fn key to use special features like brightness/volume)
      "com.apple.keyboard.fnState" = true;
    };

    # Dock settings
    dock = {
      # Set dock icon size (default is 64, range is 16-128)
      tilesize = 48;

      # Automatically hide and show the Dock
      autohide = true;
      # Speed up dock auto-hide animation
      autohide-delay = 0.0;
      autohide-time-modifier = 0.4;

      # Only show these apps in the Dock (removes all defaults)
      persistent-apps = [
        "/Applications/Google Chrome.app"
        "/Applications/Slack.app"
        "/Applications/Cursor.app"
        "/Applications/Ghostty.app"
        "/Applications/Linear.app"
        "/Applications/1Password.app"
        "/System/Applications/System Settings.app"
      ];

      # Don't show recent apps in the Dock
      show-recents = false;
    };

    # Set Chrome as the default browser
    # Note: This sets the URL handlers; a logout/login may be required
    CustomUserPreferences = {
      # Globe (🌐) key behavior: 0 = Do Nothing, 1 = Change Input Source, 2 = Show Emoji & Symbols, 3 = Start Dictation
      "com.apple.HIToolbox" = {
        AppleFnUsageType = 0;
      };
      "com.apple.LaunchServices/com.apple.launchservices.secure" = {
        LSHandlers = [
          {
            LSHandlerURLScheme = "http";
            LSHandlerRoleAll = "com.google.chrome";
          }
          {
            LSHandlerURLScheme = "https";
            LSHandlerRoleAll = "com.google.chrome";
          }
          {
            LSHandlerContentType = "public.html";
            LSHandlerRoleAll = "com.google.chrome";
          }
          {
            LSHandlerContentType = "public.xhtml";
            LSHandlerRoleAll = "com.google.chrome";
          }
        ];
      };
    };
  };

  # Firewall settings (modern nix-darwin API)
  networking.applicationFirewall = {
    # Enable the application firewall
    enable = true;
    # Allow built-in signed software to receive incoming connections
    allowSigned = true;
    # Allow downloaded signed software to receive incoming connections
    allowSignedApp = true;
    # Don't block all incoming connections
    blockAllIncoming = false;
    # Stealth mode (don't respond to ping, etc.) - disabled
    enableStealthMode = false;
  };

  # ==========================================================================
  # Launch Agents - Start applications at login
  # ==========================================================================

  # Start Karabiner Elements at login as a background service
  # Uses -j flag to launch hidden (without showing the window)
  launchd.user.agents.karabiner-elements = {
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  # ==========================================================================
  # Display Resolution - Auto-configured based on Mac model
  # ==========================================================================
  # Runs displayplacer to set "More Space" resolution for built-in display
  # Add new models as needed by running `sysctl hw.model` and `displayplacer list`

  system.activationScripts.postActivation.text = ''
    # Set display resolution to "More Space" based on Mac model
    if command -v /opt/homebrew/bin/displayplacer &> /dev/null; then
      MODEL=$(sysctl -n hw.model)
      echo "Detected Mac model: $MODEL"

      case "$MODEL" in
        # MacBook Pro 14" (M3 Pro/Max - 2023)
        "Mac15,6"|"Mac15,8"|"Mac15,10")
          /opt/homebrew/bin/displayplacer "id:1 res:1800x1169"
          echo "Set display to 'More Space' (1800x1169) for MacBook Pro 14\""
          ;;
        # MacBook Pro 14" (M4 Pro/Max - 2024)
        "Mac16,1"|"Mac16,8")
          /opt/homebrew/bin/displayplacer "id:1 res:1800x1169"
          echo "Set display to 'More Space' (1800x1169) for MacBook Pro 14\""
          ;;
        # MacBook Pro 16" (M3 Pro/Max - 2023)
        "Mac15,7"|"Mac15,9"|"Mac15,11")
          /opt/homebrew/bin/displayplacer "id:1 res:2056x1329"
          echo "Set display to 'More Space' (2056x1329) for MacBook Pro 16\""
          ;;
        # MacBook Pro 16" (M4 Pro/Max - 2024)
        "Mac16,5"|"Mac16,6")
          /opt/homebrew/bin/displayplacer "id:1 res:2056x1329"
          echo "Set display to 'More Space' (2056x1329) for MacBook Pro 16\""
          ;;
        # MacBook Air 13" (M3 - 2024)
        "Mac15,12")
          /opt/homebrew/bin/displayplacer "id:1 res:1710x1112"
          echo "Set display to 'More Space' (1710x1112) for MacBook Air 13\""
          ;;
        # MacBook Air 15" (M3 - 2024)
        "Mac15,13")
          /opt/homebrew/bin/displayplacer "id:1 res:1903x1236"
          echo "Set display to 'More Space' (1903x1236) for MacBook Air 15\""
          ;;
        *)
          echo "Unknown Mac model: $MODEL - skipping display resolution change"
          echo "Run 'displayplacer list' to find your resolution and add it to machines/default.nix"
          ;;
      esac
    else
      echo "displayplacer not found - run 'darwin-rebuild switch' again after homebrew installs it"
    fi
  '';

  # NOTE: The following settings cannot be managed declaratively via nix-darwin:
  #
  # 1. WiFi Network (Saris with 1Password)
  #    - WiFi credentials cannot be managed declaratively
  #    - Connect manually: System Settings > Wi-Fi > Saris
  #    - Use 1Password to retrieve/autofill the password

  system.stateVersion = 5;
}
