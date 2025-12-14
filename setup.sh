#!/usr/bin/env bash

set -e

# Helper function for prompts with defaults
prompt_with_default() {
    local prompt_text="$1"
    local default_value="$2"
    local result
    
    if [ -n "$default_value" ]; then
        read -p "$prompt_text [$default_value]: " result
        echo "${result:-$default_value}"
    else
        read -p "$prompt_text: " result
        echo "$result"
    fi
}

# Helper function to validate email
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Company Workstation Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Install Nix if not already installed
if ! command -v nix &> /dev/null; then
    echo "📦 Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    
    # Source nix
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Enable flakes
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# Bootstrap nix-darwin if not already set up
if ! command -v darwin-rebuild &> /dev/null; then
    echo "🍎 Bootstrapping nix-darwin..."
    nix run nix-darwin -- switch --flake "$SCRIPT_DIR#macbook"
else
    echo "🔄 Applying nix-darwin configuration..."
    darwin-rebuild switch --flake "$SCRIPT_DIR#macbook"
fi

# Setup local secrets directory
LOCAL_CONFIG_DIR="$HOME/.config/nix-config/local"
mkdir -p "$LOCAL_CONFIG_DIR"

# Interactive setup for user-specific configuration
if [ ! -f "$LOCAL_CONFIG_DIR/secrets.nix" ]; then
    echo ""
    echo "📝 Let's set up your personal configuration..."
    echo ""
    
    # Get current user as default
    CURRENT_USER="${USER:-$(whoami)}"
    
    # Prompt for Git configuration
    echo "🔧 Git Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    GIT_USER_NAME=$(prompt_with_default "Your full name (for Git commits)" "")
    while [ -z "$GIT_USER_NAME" ]; do
        echo "⚠️  Name cannot be empty"
        GIT_USER_NAME=$(prompt_with_default "Your full name (for Git commits)" "")
    done
    
    DEFAULT_EMAIL="${CURRENT_USER}@company.com"
    GIT_USER_EMAIL=$(prompt_with_default "Your email address (for Git commits)" "$DEFAULT_EMAIL")
    while ! validate_email "$GIT_USER_EMAIL"; do
        echo "⚠️  Invalid email format. Please try again."
        GIT_USER_EMAIL=$(prompt_with_default "Your email address (for Git commits)" "$DEFAULT_EMAIL")
    done
    
    # Prompt for Google account
    echo ""
    echo "🔐 Google Account (for SSO apps)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    GOOGLE_EMAIL=$(prompt_with_default "Your Google email" "$GIT_USER_EMAIL")
    while ! validate_email "$GOOGLE_EMAIL"; do
        echo "⚠️  Invalid email format. Please try again."
        GOOGLE_EMAIL=$(prompt_with_default "Your Google email" "$GIT_USER_EMAIL")
    done
    
    # Generate SSH key for GitHub
    echo ""
    echo "🔑 SSH Key Generation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"
    if [ -f "$SSH_KEY_PATH" ]; then
        echo "⚠️  SSH key already exists at $SSH_KEY_PATH"
        read -p "Generate a new one anyway? (y/N): " GENERATE_SSH
    else
        GENERATE_SSH="y"
    fi
    
    if [[ "$GENERATE_SSH" =~ ^[Yy]$ ]]; then
        echo "🔑 Generating SSH key for GitHub..."
        ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
        echo "✅ SSH key generated at $SSH_KEY_PATH"
        
        # Add to SSH config if it doesn't exist
        SSH_CONFIG="$HOME/.ssh/config"
        if [ ! -f "$SSH_CONFIG" ] || ! grep -q "Host github.com" "$SSH_CONFIG"; then
            mkdir -p "$HOME/.ssh"
            cat >> "$SSH_CONFIG" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
EOF
            chmod 600 "$SSH_CONFIG"
            echo "✅ SSH config updated"
        fi
        
        # Display and copy public key to clipboard
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 Your SSH public key:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$SSH_KEY_PATH.pub"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Copy to clipboard on macOS
        if command -v pbcopy &> /dev/null; then
            cat "$SSH_KEY_PATH.pub" | pbcopy
            echo "✅ SSH key copied to clipboard!"
        fi
        
        # Open GitHub SSH settings in browser
        if command -v open &> /dev/null; then
            echo ""
            echo "🌐 Opening GitHub SSH settings in your browser..."
            open "https://github.com/settings/ssh/new"
            echo ""
            echo "💡 Instructions:"
            echo "   1. The SSH key is already copied to your clipboard"
            echo "   2. Paste it into the 'Key' field on GitHub"
            echo "   3. Give it a title (e.g., 'MacBook Pro')"
            echo "   4. Click 'Add SSH key'"
            echo ""
            read -p "Press enter after you've added the key to GitHub..."
            
            # Test SSH connection
            echo ""
            echo "🔍 Testing SSH connection to GitHub..."
            if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
                echo "✅ SSH key successfully configured!"
            else
                echo "⚠️  SSH test inconclusive. You may need to add the key manually."
                echo "   Run: ssh -T git@github.com to test later"
            fi
        else
            echo ""
            echo "💡 Add this SSH key to GitHub:"
            echo "   1. Go to: https://github.com/settings/ssh/new"
            echo "   2. Paste the key above"
            echo "   3. Click 'Add SSH key'"
            read -p "Press enter when done..."
        fi
    fi
    
    # Create secrets.nix file
    echo ""
    echo "📝 Creating local secrets file..."
    cat > "$LOCAL_CONFIG_DIR/secrets.nix" << EOF
# secrets.nix
# This file is automatically generated by setup.sh
# It contains your personal configuration and is gitignored

{ config, pkgs, ... }:

{
  # Git configuration
  programs.git = {
    userName = "${GIT_USER_NAME}";
    userEmail = "${GIT_USER_EMAIL}";
  };
  
  # You can add other personal overrides here
}
EOF
    echo "✅ Secrets file created at $LOCAL_CONFIG_DIR/secrets.nix"
    
    # Rebuild with user-specific config
    echo ""
    echo "🔧 Applying configuration with your personal settings..."
    darwin-rebuild switch --flake "$SCRIPT_DIR#macbook"
else
    echo "✅ Personal configuration already exists at $LOCAL_CONFIG_DIR/secrets.nix"
    echo "💡 To update it, edit the file and run: darwin-rebuild switch --flake .#macbook"
fi

# GUI applications are now managed via nix-darwin's homebrew module
# They will be installed automatically when darwin-rebuild runs
echo "📱 GUI applications (Cursor, Slack, Linear, Docker, Karabiner) will be installed via nix-darwin..."

# Setup GitHub CLI
if command -v gh &> /dev/null; then
    echo ""
    echo "🔐 Setting up GitHub CLI..."
    if ! gh auth status &> /dev/null; then
        echo "📝 Authenticating with GitHub..."
        echo "💡 Choose: GitHub.com > HTTPS > Login with a web browser"
        gh auth login
    else
        echo "✅ GitHub already authenticated"
    fi
else
    echo "⚠️  GitHub CLI will be available after rebuild - run 'gh auth login' then"
fi

# Setup AWS CLI
if command -v aws &> /dev/null; then
    echo ""
    echo "☁️  Setting up AWS CLI..."
    if [ ! -f "$HOME/.aws/config" ]; then
        echo "📝 Configuring AWS SSO..."
        echo "💡 You'll need your AWS SSO start URL and region"
        read -p "Configure AWS now? (y/N): " CONFIGURE_AWS
        if [[ "$CONFIGURE_AWS" =~ ^[Yy]$ ]]; then
            aws configure sso
        else
            echo "⚠️  Run 'aws configure sso' later to set up AWS access"
        fi
    else
        echo "✅ AWS CLI configured"
    fi
else
    echo "⚠️  AWS CLI will be available after rebuild - run 'aws configure sso' then"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Final steps:"
echo ""
echo "1. 🔐 Sign in to applications:"
echo "   • Cursor: Open and sign in with Google SSO"
if command -v open &> /dev/null; then
    echo "     → Opening Cursor..."
    open -a Cursor 2>/dev/null || echo "     (Cursor will be installed shortly)"
fi
echo "   • Linear: Open and sign in with Google SSO"
if command -v open &> /dev/null; then
    echo "     → Opening Linear..."
    open -a Linear 2>/dev/null || echo "     (Linear will be installed shortly)"
fi
echo "   • Slack: Open and sign in with Google SSO"
if command -v open &> /dev/null; then
    echo "     → Opening Slack..."
    open -a Slack 2>/dev/null || echo "     (Slack will be installed shortly)"
fi
echo ""
echo "2. 🐳 Docker:"
echo "   • Open Docker Desktop and start the daemon"
if command -v open &> /dev/null; then
    echo "     → Opening Docker..."
    open -a Docker 2>/dev/null || echo "     (Docker will be installed shortly)"
fi
echo ""
echo "3. 🔄 Restart your terminal to apply all changes"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Welcome to the team!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

