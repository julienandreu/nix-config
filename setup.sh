#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
FLAKE="$SCRIPT_DIR#mac"
SECRETS_DIR="$HOME/.config/nix-config/local"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"

# =============================================================================
# Logging Functions
# =============================================================================

# Colors (only if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

log_header() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${BLUE}  $1${RESET}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

log_section() {
    echo ""
    echo -e "${CYAN}▸ $1${RESET}"
    echo -e "${DIM}──────────────────────────────────────────────────${RESET}"
}

log_info() {
    echo -e "${BLUE}ℹ${RESET}  $1"
}

log_success() {
    echo -e "${GREEN}✓${RESET}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${RESET}  $1"
}

log_error() {
    echo -e "${RED}✗${RESET}  $1"
}

log_step() {
    echo -e "${DIM}→${RESET}  $1"
}

# =============================================================================
# Helper Functions
# =============================================================================

prompt_with_default() {
    local prompt_text="$1"
    local default_value="$2"
    local result

    if [[ -n "$default_value" ]]; then
        read -rp "   $prompt_text [$default_value]: " result
        echo "${result:-$default_value}"
    else
        read -rp "   $prompt_text: " result
        echo "$result"
    fi
}

validate_email() {
    local email="$1"
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
}

# =============================================================================
# Installation Functions
# =============================================================================

check_nix_installation_mode() {
    # Check if Nix is installed in multi-user mode
    # Multi-user mode has:
    # - /nix directory owned by root
    # - nix-daemon service running
    # - Build users (_nixbld1, etc.)
    
    if [[ ! -d "/nix" ]]; then
        # Check if there's a user-level Nix installation
        if [[ -d "$HOME/.nix-profile" ]] || [[ -d "$HOME/.nix" ]]; then
            echo "single-user"
        else
            echo "none"
        fi
        return 0
    fi
    
    # Check if /nix is owned by root (multi-user) or user (single-user)
    local nix_owner
    if [[ "$OSTYPE" == "darwin"* ]]; then
        nix_owner=$(stat -f "%Su" /nix 2>/dev/null || echo "")
    else
        nix_owner=$(stat -c "%U" /nix 2>/dev/null || echo "")
    fi
    
    if [[ "$nix_owner" == "root" ]]; then
        # Check if daemon is running
        if sudo launchctl list 2>/dev/null | grep -q "com.nixos.nix-daemon"; then
            echo "multi-user"
        else
            # Check if daemon plist exists
            if [[ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]] || \
               [[ -f "/Library/LaunchDaemons/com.nixos.nix-daemon.plist" ]]; then
                echo "multi-user-incomplete"
            else
                # Root-owned /nix but no daemon - might be transitioning
                echo "multi-user-incomplete"
            fi
        fi
    else
        echo "single-user"
    fi
}

uninstall_single_user_nix() {
    log_warning "Single-user Nix installation detected"
    log_info "nix-darwin requires multi-user daemon installation"
    echo ""
    log_step "To fix this, you need to uninstall the current Nix installation"
    log_step "and reinstall it in multi-user mode."
    echo ""
    read -rp "   Uninstall Nix now and reinstall in multi-user mode? (Y/n): " uninstall_choice
    uninstall_choice="${uninstall_choice:-y}"
    
    if [[ ! "$uninstall_choice" =~ ^[Yy]$ ]]; then
        log_error "Cannot proceed without multi-user Nix installation"
        log_step "Manually uninstall Nix, then run this script again"
        log_step "Or set nix.enable = false in your nix-darwin config (not recommended)"
        exit 1
    fi
    
    log_info "Uninstalling single-user Nix installation..."
    
    # Remove Nix directories
    if [[ -d "$HOME/.nix-profile" ]]; then
        rm -rf "$HOME/.nix-profile"
    fi
    if [[ -d "$HOME/.nix" ]]; then
        rm -rf "$HOME/.nix"
    fi
    
    # Remove Nix from shell config files
    local shell_configs=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
    )
    
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]]; then
            # Remove lines containing .nix-profile
            sed -i.bak '/\.nix-profile/d' "$config_file" 2>/dev/null || true
            rm -f "${config_file}.bak" 2>/dev/null || true
        fi
    done
    
    # Remove /nix if it exists and is owned by user
    if [[ -d "/nix" ]]; then
        local nix_owner
        nix_owner=$(stat -f "%Su" /nix 2>/dev/null || echo "")
        if [[ "$nix_owner" != "root" ]]; then
            log_info "Removing /nix directory (requires sudo)..."
            
            # Check if /nix is a volume mount (macOS installer creates it as a volume)
            local mount_info
            mount_info=$(mount | grep "on /nix" || true)
            if [[ -n "$mount_info" ]]; then
                log_info "Unmounting /nix volume..."
                # Try diskutil first (macOS-specific)
                sudo diskutil unmount force /nix 2>/dev/null || \
                sudo diskutil unmount /nix 2>/dev/null || \
                sudo umount -f /nix 2>/dev/null || \
                sudo umount /nix 2>/dev/null || true
                # Wait a moment for unmount to complete
                sleep 1
            fi
            
            # Stop any Nix processes that might be using /nix
            if command -v nix-daemon &>/dev/null; then
                sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
                sudo launchctl unload /Library/LaunchDaemons/com.nixos.nix-daemon.plist 2>/dev/null || true
            fi
            
            # Kill any nix processes
            sudo pkill -9 nix-daemon 2>/dev/null || true
            sudo pkill -9 nix 2>/dev/null || true
            
            # Wait a moment for processes to terminate
            sleep 2
            
            # Remove .Trashes directory if it exists (macOS creates this automatically)
            if [[ -d "/nix/.Trashes" ]]; then
                sudo rm -rf /nix/.Trashes 2>/dev/null || true
            fi
            
            # Try to remove /nix directory
            # Use a more forceful approach: remove contents first, then directory
            # Remove visible files first
            sudo find /nix -mindepth 1 -maxdepth 1 ! -name '.Trashes' -exec rm -rf {} + 2>/dev/null || true
            # Remove .Trashes if it still exists
            sudo rm -rf /nix/.Trashes 2>/dev/null || true
            # Try to remove hidden files/directories (but not . and ..)
            sudo find /nix -mindepth 1 -maxdepth 1 -name '.*' ! -name '.' ! -name '..' -exec rm -rf {} + 2>/dev/null || true
            
            # Try to remove the directory itself
            if sudo rmdir /nix 2>/dev/null || sudo rm -rf /nix 2>/dev/null; then
                log_success "/nix directory removed"
            else
                # Check if directory still exists
                if [[ -d "/nix" ]]; then
                    log_warning "Could not fully remove /nix directory (may be in use)"
                    log_step "Checking for processes using /nix..."
                    if command -v lsof &>/dev/null; then
                        sudo lsof +D /nix 2>/dev/null | head -20 || true
                    fi
                    log_step "You may need to:"
                    log_step "  1. Close all terminal windows and applications"
                    log_step "  2. Restart your computer"
                    log_step "  3. Run this script again"
                    log_step "Or manually remove /nix after ensuring no processes are using it"
                    # Continue anyway - multi-user installer might handle it
                else
                    log_success "/nix directory removed"
                fi
            fi
        fi
    fi
    
    log_success "Single-user Nix installation cleanup completed"
}

install_nix() {
    local nix_mode
    nix_mode=$(check_nix_installation_mode)
    
    case "$nix_mode" in
        "multi-user")
            log_success "Nix is already installed in multi-user mode"
            # Source nix environment if not already in PATH
            if ! command -v nix &>/dev/null; then
                log_info "Setting up Nix environment..."
                if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
                    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                fi
            fi
            return 0
            ;;
        "multi-user-incomplete")
            log_warning "Nix appears to be in multi-user mode but daemon is not running"
            log_info "Attempting to start nix-daemon..."
            sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
            if command -v nix &>/dev/null; then
                log_success "Nix daemon started"
                return 0
            fi
            ;;
        "single-user")
            uninstall_single_user_nix
            ;;
        "none")
            # No Nix installed, proceed with installation
            ;;
    esac
    
    log_info "Installing Nix in multi-user daemon mode..."
    # Use --daemon flag to enforce multi-user installation
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
    log_success "Nix installed successfully in multi-user mode"
    
    # Source the nix-daemon environment
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
}

install_homebrew() {
    # Check if Homebrew is already installed
    if command -v brew &>/dev/null; then
        log_success "Homebrew is already installed"
        return 0
    fi

    # Check common Homebrew locations for Apple Silicon and Intel Macs
    if [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]; then
        log_success "Homebrew is already installed (not in PATH yet)"
        return 0
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for the current session
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
}

enable_flakes() {
    mkdir -p ~/.config/nix
    if grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
        log_success "Flakes already enabled"
    else
        echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
        log_success "Flakes enabled"
    fi
}

generate_local_config() {
    local local_nix="$SCRIPT_DIR/local.nix"
    log_info "Generating local.nix for user: $USER"

    # Detect system architecture
    local arch
    arch=$(uname -m)
    local system
    case "$arch" in
        arm64) system="aarch64-darwin" ;;
        x86_64) system="x86_64-darwin" ;;
        *) 
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    cat >"$local_nix" <<EOF
# local.nix - Machine-specific configuration
# This file is generated by setup.sh and staged in git
# Regenerate with: ./setup.sh or manually edit as needed

{
  system = "$system";
  username = "$USER";
  homeDirectory = "$HOME";
}
EOF

    log_success "Generated local.nix (system=$system, user=$USER)"
}

build_system() {
    log_info "Building system as $(whoami)..."
    FLAKE_DIR="$SCRIPT_DIR" nix build "$SCRIPT_DIR#darwinConfigurations.mac.system" --impure
    log_success "System built successfully"
}

cleanup_home_manager_backups() {
    log_info "Cleaning up stale home-manager backup files..."
    
    # List of files managed by home-manager that might have backups
    local managed_files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.gitconfig"
    )
    
    local cleaned=0
    for file in "${managed_files[@]}"; do
        if [[ -f "${file}.backup" ]]; then
            rm -f "${file}.backup"
            ((cleaned++))
        fi
    done
    
    # Also clean any nested backup files (e.g., .zshrc.backup.backup)
    find "$HOME" -maxdepth 1 -name "*.backup*" -type f 2>/dev/null | while read -r backup; do
        rm -f "$backup"
        ((cleaned++))
    done
    
    if [[ $cleaned -gt 0 ]]; then
        log_success "Removed $cleaned backup file(s)"
    else
        log_success "No backup files to clean"
    fi
}

activate_system() {
    # Clean up old backups before activation to ensure fresh generation
    cleanup_home_manager_backups
    
    log_info "Activating system (requires sudo)..."
    sudo FLAKE_DIR="$SCRIPT_DIR" "$SCRIPT_DIR/result/sw/bin/darwin-rebuild" switch --flake "$FLAKE" --impure
    log_success "System activated"
}

# =============================================================================
# Configuration Functions
# =============================================================================

setup_git_config() {
    log_section "Git Configuration"

    local current_user="${USER:-$(whoami)}"
    local default_email="${current_user}@example.com"

    GIT_USER_NAME=$(prompt_with_default "Your full name (for Git commits)" "")
    while [[ -z "$GIT_USER_NAME" ]]; do
        log_warning "Name cannot be empty"
        GIT_USER_NAME=$(prompt_with_default "Your full name (for Git commits)" "")
    done

    GIT_USER_EMAIL=$(prompt_with_default "Your email address (for Git commits)" "$default_email")
    while ! validate_email "$GIT_USER_EMAIL"; do
        log_warning "Invalid email format, please try again"
        GIT_USER_EMAIL=$(prompt_with_default "Your email address (for Git commits)" "$default_email")
    done

    log_success "Git configuration captured"
}

setup_ssh_key() {
    log_section "SSH Key Generation"

    local generate_ssh="y"

    if [[ -f "$SSH_KEY_PATH" ]]; then
        log_warning "SSH key already exists at $SSH_KEY_PATH"
        read -rp "   Generate a new one anyway? (y/N): " generate_ssh
        generate_ssh="${generate_ssh:-n}"
    fi

    if [[ ! "$generate_ssh" =~ ^[Yy]$ ]]; then
        log_info "Skipping SSH key generation"
        return 0
    fi

    log_info "Generating SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
    log_success "SSH key generated at $SSH_KEY_PATH"

    configure_ssh_config
    display_and_copy_ssh_key
    setup_github_ssh
}

configure_ssh_config() {
    local ssh_config="$HOME/.ssh/config"

    if [[ -f "$ssh_config" ]] && grep -q "Host github.com" "$ssh_config"; then
        log_info "SSH config already contains GitHub entry"
        return 0
    fi

    mkdir -p "$HOME/.ssh"
    cat >>"$ssh_config" <<EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
EOF
    chmod 600 "$ssh_config"
    log_success "SSH config updated"
}

display_and_copy_ssh_key() {
    echo ""
    echo -e "${DIM}──────────────────────────────────────────────────${RESET}"
    echo -e "${BOLD}Your SSH public key:${RESET}"
    echo ""
    cat "$SSH_KEY_PATH.pub"
    echo ""
    echo -e "${DIM}──────────────────────────────────────────────────${RESET}"

    if command -v pbcopy &>/dev/null; then
        pbcopy <"$SSH_KEY_PATH.pub"
        log_success "SSH key copied to clipboard"
    fi
}

setup_github_ssh() {
    if ! command -v open &>/dev/null; then
        echo ""
        log_info "Add this SSH key to GitHub:"
        log_step "Go to: https://github.com/settings/ssh/new"
        log_step "Paste the key above"
        log_step "Click 'Add SSH key'"
        read -rp "   Press Enter when done..."
        return 0
    fi

    log_info "Opening GitHub SSH settings in your browser..."
    open "https://github.com/settings/ssh/new"
    echo ""
    log_info "Instructions:"
    log_step "The SSH key is already copied to your clipboard"
    log_step "Paste it into the 'Key' field on GitHub"
    log_step "Give it a title (e.g., 'MacBook Pro')"
    log_step "Click 'Add SSH key'"
    echo ""
    read -rp "   Press Enter after you've added the key to GitHub..."

    test_github_ssh
}

test_github_ssh() {
    log_info "Testing SSH connection to GitHub..."
    if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        log_success "SSH key successfully configured"
    else
        log_warning "SSH test inconclusive - you may need to verify manually"
        log_step "Run: ssh -T git@github.com"
    fi
}

create_secrets_file() {
    log_section "Creating Local Secrets"

    mkdir -p "$SECRETS_DIR"

    cat >"$SECRETS_DIR/secrets.nix" <<EOF
# secrets.nix
# This file is automatically generated by setup.sh
# It contains your personal configuration and is gitignored

{ config, pkgs, ... }:

{
  # Git configuration
  programs.git.settings.user = {
    name = "${GIT_USER_NAME}";
    email = "${GIT_USER_EMAIL}";
  };

  # You can add other personal overrides here
}
EOF

    log_success "Secrets file created at $SECRETS_DIR/secrets.nix"
}

apply_personal_config() {
    log_info "Applying configuration with your personal settings..."
    sudo FLAKE_DIR="$SCRIPT_DIR" "$SCRIPT_DIR/result/sw/bin/darwin-rebuild" switch --flake "$SCRIPT_DIR#mac" --impure
    log_success "Personal configuration applied"
}

# =============================================================================
# Post-Install Setup
# =============================================================================

show_final_steps() {
    log_header "System Installation Complete"

    echo ""
    log_success "Nix-darwin system has been installed and configured!"
    echo ""
    
    log_warning "IMPORTANT: Start a new terminal session to load shell changes!"
    log_step "Close this terminal and open a new one, or run: exec zsh"
    echo ""

    log_info "Next step: Run the onboarding wizard to set up your applications."
    echo ""
    log_step "The onboarding wizard will guide you through:"
    log_step "  • Google Chrome (default browser + account sync)"
    log_step "  • GitHub (web login + CLI authentication)"
    log_step "  • SSH Key (for secure Git access)"
    log_step "  • 1Password (password manager)"
    log_step "  • AWS Console & CLI (cloud access)"
    log_step "  • Cursor (AI code editor)"
    log_step "  • Linear (project management)"
    log_step "  • Slack (team communication)"
    echo ""
}

run_onboarding() {
    local onboard_script="$SCRIPT_DIR/onboard.sh"

    if [[ ! -x "$onboard_script" ]]; then
        log_warning "Onboarding script not found or not executable"
        log_step "Run manually: ./onboard.sh"
        return 0
    fi

    echo ""
    read -rp "   Would you like to run the onboarding wizard now? (Y/n): " run_onboard
    run_onboard="${run_onboard:-y}"

    if [[ "$run_onboard" =~ ^[Yy]$ ]]; then
        echo ""
        log_info "Starting onboarding wizard..."
        echo ""
        exec "$onboard_script"
    else
        echo ""
        log_info "You can run the onboarding wizard later with:"
        log_step "./onboard.sh"
        echo ""
        echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}${GREEN}  🎉 System setup complete! Run ./onboard.sh when ready${RESET}"
        echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_header "🚀 Nix Configuration Setup"

    check_macos
    cd "$SCRIPT_DIR"

    # Phase 0: Admin permissions
    log_section "Admin Permissions"
    sudo -v

    # Phase 1: Install Nix
    log_section "Installing Nix"
    install_nix
    enable_flakes

    # Fix SSL certificates (link Nix certificates to system location)
    log_info "Fixing SSL certificates..."
    sudo rm -f /etc/ssl/certs/ca-certificates.crt
    sudo ln -s /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
    log_success "SSL certificates fixed"

    # Phase 2: Install Homebrew
    log_section "Installing Homebrew"
    install_homebrew

    # Phase 3: Generate local configuration
    log_section "Local Configuration"
    generate_local_config

    # Phase 4: Build and activate system
    log_section "Building System"
    build_system
    activate_system

    # Phase 5: Personal configuration
    mkdir -p "$SECRETS_DIR"
    if [[ -f "$SECRETS_DIR/secrets.nix" ]]; then
        log_section "Personal Configuration"
        log_success "Personal configuration already exists"
        log_step "Edit $SECRETS_DIR/secrets.nix to update"
        log_step "Run: darwin-rebuild switch --flake .#mac --impure"
    else
        log_header "📝 Personal Configuration"
        setup_git_config
        setup_ssh_key
        create_secrets_file
        apply_personal_config
    fi

    # Done - show summary and offer onboarding
    show_final_steps
    run_onboarding
}

main "$@"
