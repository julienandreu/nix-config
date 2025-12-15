{ pkgs, username, ... }:

{
  system.primaryUser = username;

  programs.zsh.enable = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    casks = [
      "1password"
      "cursor"
      "docker-desktop"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "linear-linear"
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
    # Dock settings
    dock = {
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

  # NOTE: The following settings cannot be managed declaratively via nix-darwin:
  #
  # 1. Display Resolution ("More Space")
  #    - Must be set manually: System Settings > Displays > Resolution > More Space
  #    - Or use `displayplacer` CLI tool (available via homebrew)
  #
  # 2. WiFi Network (Saris with 1Password)
  #    - WiFi credentials cannot be managed declaratively
  #    - Connect manually: System Settings > Wi-Fi > Saris
  #    - Use 1Password to retrieve/autofill the password

  system.stateVersion = 5;
}
