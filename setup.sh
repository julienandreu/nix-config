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

prompt_catppuccin_flavor() {
    log_section "Catppuccin Theme Selection" >&2
    echo "" >&2
    log_info "Choose your Catppuccin flavor:" >&2
    echo "" >&2
    echo "  🌻  1) Latte      - Light theme" >&2
    echo "  🪴  2) Frappé     - Medium-dark theme" >&2
    echo "  🌺  3) Macchiato  - Dark theme" >&2
    echo "  🌿  4) Mocha      - Darkest theme (recommended)" >&2
    echo "" >&2

    local flavor="mocha"  # Default to mocha
    while true; do
        local choice
        echo -e "${CYAN}   Enter your choice [1=Latte, 2=Frappé, 3=Macchiato, 4=Mocha] (default: 4)${RESET}" >&2
        read -rp "   → " choice

        # Default to mocha if empty or just Enter pressed
        if [[ -z "$choice" ]]; then
            flavor="mocha"
            log_success "Selected: 🌿 Mocha (darkest theme) [default]" >&2
            break
        fi

        case "$choice" in
            1)
                flavor="latte"
                log_success "Selected: 🌻 Latte (light theme)" >&2
                break
                ;;
            2)
                flavor="frappe"
                log_success "Selected: 🪴 Frappé (medium-dark theme)" >&2
                break
                ;;
            3)
                flavor="macchiato"
                log_success "Selected: 🌺 Macchiato (dark theme)" >&2
                break
                ;;
            4)
                flavor="mocha"
                log_success "Selected: 🌿 Mocha (darkest theme)" >&2
                break
                ;;
            *)
                log_warning "Invalid choice '$choice'. Please enter 1, 2, 3, or 4 (or press Enter for default)." >&2
                echo "" >&2
                ;;
        esac
    done

    # Output only the flavor to stdout (for command substitution)
    echo "$flavor"
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

    # Prompt for Catppuccin flavor
    local catppuccin_flavor
    catppuccin_flavor=$(prompt_catppuccin_flavor)

    cat >"$local_nix" <<EOF
# local.nix - Machine-specific configuration
# This file is generated by setup.sh and staged in git
# Regenerate with: ./setup.sh or manually edit as needed

{
  system = "$system";
  username = "$USER";
  homeDirectory = "$HOME";
  catppuccinFlavor = "$catppuccin_flavor";
}
EOF

    log_success "Generated local.nix (system=$system, user=$USER, flavor=$catppuccin_flavor)"
}

build_system() {
    log_info "Building system as $(whoami)..."

    # Validate that local.nix exists and has required fields
    if [[ ! -f "$SCRIPT_DIR/local.nix" ]]; then
        log_error "local.nix not found!"
        log_step "Run ./setup.sh to generate it, or copy local.nix.template to local.nix"
        return 1
    fi

    # Quick validation that local.nix has required fields
    log_info "Validating local.nix configuration..."
    if ! grep -q "username" "$SCRIPT_DIR/local.nix" || ! grep -q "system" "$SCRIPT_DIR/local.nix"; then
        log_error "local.nix is missing required fields (username or system)"
        log_step "Check $SCRIPT_DIR/local.nix and ensure it has username and system fields"
        return 1
    fi
    log_success "local.nix validation passed"

    # Build the system - this will fail if machines/default.nix can't be loaded
    log_info "Building nix-darwin system (this validates that machines/default.nix loads correctly)..."
    if FLAKE_DIR="$SCRIPT_DIR" nix build "$SCRIPT_DIR#darwinConfigurations.mac.system" --impure 2>&1 | tee /tmp/nix-build.log; then
        log_success "System built successfully - machines/default.nix was loaded correctly"
    else
        log_error "System build failed"
        if grep -q "undefined variable" /tmp/nix-build.log 2>/dev/null; then
            log_error "Module evaluation error detected"
            log_step "This might indicate machines/default.nix is missing required arguments"
            log_step "Check that username is set in local.nix"
        fi
        log_step "Check the error messages above for details"
        rm -f /tmp/nix-build.log
        return 1
    fi
    rm -f /tmp/nix-build.log
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

backup_critical_files() {
    log_info "Backing up critical configuration files..."

    # List of files that home-manager will manage and need backup
    local critical_files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
    )

    local backed_up=0
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]] && [[ ! -f "${file}.backup" ]]; then
            cp "$file" "${file}.backup"
            ((backed_up++))
        fi
    done

    if [[ $backed_up -gt 0 ]]; then
        log_success "Backed up $backed_up file(s)"
    fi
}

activate_system() {
    log_info "Activating system (requires sudo)..."

    # Set environment variable to allow home-manager to overwrite existing backup files
    # This ensures backupFileExtension works even if backup files from previous runs exist
    export HOME_MANAGER_BACKUP_OVERWRITE=1

    # Handle nix-darwin /etc file conflicts proactively
    # nix-darwin wants to manage /etc/bashrc and /etc/zshrc
    # These may be regular files or symlinks (macOS often uses symlinks)
    # We handle them BEFORE activation to prevent errors
    log_info "Checking for /etc file conflicts that would prevent activation..."
    local etc_files=("/etc/bashrc" "/etc/zshrc")
    local handled_files=0

    for etc_file in "${etc_files[@]}"; do
        # Check if file exists (regular file, symlink, or directory)
        if [[ -e "$etc_file" ]]; then
            local backup_name="${etc_file}.before-nix-darwin"

            # Always handle the file if it exists, even if backup exists
            # This ensures nix-darwin can create its own files
            if [[ -L "$etc_file" ]]; then
                # It's a symlink - remove it and save target info
                log_info "Removing symlink $(basename "$etc_file") (points to $(readlink "$etc_file"))..."
                local symlink_target
                symlink_target=$(readlink "$etc_file")

                # Remove the symlink
                if sudo rm "$etc_file" 2>/dev/null; then
                    # Save the symlink target info if backup doesn't exist
                    if [[ ! -e "$backup_name" ]]; then
                        echo "# Original symlink target: $symlink_target" | sudo tee "$backup_name" > /dev/null
                    fi
                    handled_files=$((handled_files + 1))
                    log_success "Removed symlink $(basename "$etc_file")"
                else
                    log_error "Failed to remove symlink $etc_file"
                    log_step "You may need to manually run: sudo rm $etc_file"
                    return 1
                fi
            elif [[ -f "$etc_file" ]]; then
                # Regular file - rename it to backup
                log_info "Backing up $(basename "$etc_file") to $(basename "$backup_name")..."
                if sudo mv "$etc_file" "$backup_name" 2>/dev/null; then
                    handled_files=$((handled_files + 1))
                    log_success "Backed up $(basename "$etc_file")"
                else
                    log_error "Failed to backup $etc_file"
                    log_step "You may need to manually run: sudo mv $etc_file $backup_name"
                    return 1
                fi
            fi
        else
            log_info "✓ $(basename "$etc_file") doesn't exist (no conflict)"
        fi
    done

    if [[ $handled_files -gt 0 ]]; then
        log_success "Handled $handled_files /etc file(s) that would have caused activation to fail"
    fi

    # Define critical files that home-manager manages
    local critical_files=("$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile")

    # Remove any nested backup files (.backup.backup) that might cause issues
    find "$HOME" -maxdepth 1 -name "*.backup.backup" -type f 2>/dev/null | while read -r backup; do
        rm -f "$backup"
    done

    # Try activation - home-manager should create backups via backupFileExtension
    # HOME_MANAGER_BACKUP_OVERWRITE allows overwriting existing backups if needed
    local rebuild_output
    rebuild_output=$(mktemp)
    if sudo -E FLAKE_DIR="$SCRIPT_DIR" "$SCRIPT_DIR/result/sw/bin/darwin-rebuild" switch --flake "$FLAKE" --impure 2>&1 | tee "$rebuild_output"; then
        rm -f "$rebuild_output"
        log_success "System activated"

        # Verify that key settings from machines/default.nix were applied
        log_info "Verifying system configuration..."
        verify_system_config
        return 0
    fi

    # Check if failure was due to /etc file conflicts (nix-darwin specific)
    if grep -q "Unexpected files in /etc" "$rebuild_output" 2>/dev/null; then
        log_warning "nix-darwin detected /etc file conflicts"
        log_info "Attempting to handle /etc file conflicts automatically..."

        # Extract /etc files from error message - look for lines like "  /etc/bashrc" or "  /etc/zshrc"
        local etc_conflicts=()
        while IFS= read -r line; do
            # Match lines that contain /etc/bashrc or /etc/zshrc
            if [[ "$line" =~ /etc/(bashrc|zshrc) ]]; then
                local etc_file="/etc/${BASH_REMATCH[1]}"
                if [[ -e "$etc_file" ]]; then
                    etc_conflicts+=("$etc_file")
                fi
            fi
        done < <(grep -E "/etc/(bashrc|zshrc)" "$rebuild_output" 2>/dev/null || true)

        # If we didn't find them in the error message, check for them directly
        if [[ ${#etc_conflicts[@]} -eq 0 ]]; then
            [[ -e "/etc/bashrc" ]] && etc_conflicts+=("/etc/bashrc")
            [[ -e "/etc/zshrc" ]] && etc_conflicts+=("/etc/zshrc")
        fi

        # Handle /etc files if found (may be symlinks or regular files)
        for etc_file in "${etc_conflicts[@]}"; do
            local backup_name="${etc_file}.before-nix-darwin"
            if [[ ! -e "$backup_name" ]]; then
                if [[ -L "$etc_file" ]]; then
                    # It's a symlink - remove it
                    log_info "Removing symlink $(basename "$etc_file")..."
                    local symlink_target
                    symlink_target=$(readlink "$etc_file")
                    if sudo rm "$etc_file" 2>/dev/null; then
                        echo "# Original symlink target: $symlink_target" | sudo tee "$backup_name" > /dev/null
                        log_success "Removed symlink $(basename "$etc_file")"
                    else
                        log_error "Failed to remove symlink $etc_file"
                        log_step "You may need to manually run: sudo rm $etc_file"
                    fi
                elif [[ -f "$etc_file" ]]; then
                    # Regular file - rename it
                    log_info "Renaming $(basename "$etc_file") to $(basename "$backup_name")..."
                    if sudo mv "$etc_file" "$backup_name" 2>/dev/null; then
                        log_success "Renamed $(basename "$etc_file")"
                    else
                        log_error "Failed to rename $etc_file"
                        log_step "You may need to manually run: sudo mv $etc_file $backup_name"
                    fi
                fi
            else
                log_info "$(basename "$etc_file") already backed up"
                # Still remove the existing file/symlink
                if [[ -L "$etc_file" ]]; then
                    sudo rm "$etc_file" 2>/dev/null || true
                elif [[ -f "$etc_file" ]]; then
                    sudo rm "$etc_file" 2>/dev/null || true
                fi
            fi
        done

        # Retry activation after handling /etc conflicts
        if [[ ${#etc_conflicts[@]} -gt 0 ]]; then
            log_info "Retrying activation after handling /etc file conflicts..."
            if sudo -E FLAKE_DIR="$SCRIPT_DIR" "$SCRIPT_DIR/result/sw/bin/darwin-rebuild" switch --flake "$FLAKE" --impure 2>&1 | tee "$rebuild_output"; then
                rm -f "$rebuild_output"
                log_success "System activated after handling /etc conflicts"
                verify_system_config
                return 0
            fi
        fi
    fi

    # Check if failure was due to file conflicts
    if grep -q "would be clobbered" "$rebuild_output" 2>/dev/null; then
        log_warning "File conflicts detected - home-manager backup mechanism may not be working"
        log_info "Attempting workaround: temporarily moving conflicting files..."

        # Extract conflicting files from the error message
        # Format: "Existing file '/path/to/file' would be clobbered"
        local moved_files=()
        while IFS= read -r line; do
            # Extract file path between single quotes using sed
            local conflicting_file
            conflicting_file=$(echo "$line" | sed -n "s/.*Existing file '\([^']*\)' would be clobbered.*/\1/p")
            if [[ -n "$conflicting_file" ]] && [[ -f "$conflicting_file" ]]; then
                local backup_name="${conflicting_file}.backup.manual"
                log_info "Moving $(basename "$conflicting_file") to $(basename "$backup_name")..."
                mv "$conflicting_file" "$backup_name"
                moved_files+=("$backup_name")
            fi
        done < <(grep "would be clobbered" "$rebuild_output" 2>/dev/null || true)

        # Also check critical files as fallback (in case extraction didn't work)
        for file in "${critical_files[@]}"; do
            if grep -q "$(basename "$file")" "$rebuild_output" 2>/dev/null && [[ -f "$file" ]]; then
                local backup_name="${file}.backup.manual"
                # Check if backup already exists (from previous loop)
                if [[ ! -f "$backup_name" ]]; then
                    log_info "Moving $(basename "$file") to $(basename "$backup_name")..."
                    mv "$file" "$backup_name"
                    moved_files+=("$backup_name")
                fi
            fi
        done

        # Retry activation
        log_info "Retrying activation with files moved out of the way..."
        if sudo -E FLAKE_DIR="$SCRIPT_DIR" "$SCRIPT_DIR/result/sw/bin/darwin-rebuild" switch --flake "$FLAKE" --impure; then
            log_success "System activated"
            if [[ ${#moved_files[@]} -gt 0 ]]; then
                log_warning "Some files were moved to .backup.manual - you may want to merge them manually"
            fi
            rm -f "$rebuild_output"
            return 0
        fi
    fi

    rm -f "$rebuild_output"
    log_error "System activation failed"
    log_step "Check the error messages above for details"
    log_step "You may need to manually resolve file conflicts"
    log_step "Or run: darwin-rebuild switch --flake .#mac --impure"
    return 1
}

install_node_lts() {
    log_info "Installing Node.js LTS via fnm..."

    # Source fnm environment if available
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    # Check if fnm is available
    if ! command -v fnm &>/dev/null; then
        log_warning "fnm not found in PATH, skipping Node.js LTS installation"
        log_step "Node.js LTS will be installed automatically on first shell startup"
        return 0
    fi

    # Initialize fnm for this session
    eval "$(fnm env --shell bash)"

    # Check if Node.js LTS is already installed
    if [ -f "$HOME/.fnm/aliases/default" ]; then
        log_success "Node.js LTS already installed"
        return 0
    fi

    # Install Node.js LTS
    if fnm install --lts; then
        fnm default lts-latest
        log_success "Node.js LTS installed and set as default"
    else
        log_warning "Failed to install Node.js LTS"
        log_step "You can install it manually later with: fnm install --lts && fnm default lts-latest"
    fi
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

    # Set environment variable to allow home-manager to overwrite existing backup files
    export HOME_MANAGER_BACKUP_OVERWRITE=1

    if sudo -E FLAKE_DIR="$SCRIPT_DIR" "$SCRIPT_DIR/result/sw/bin/darwin-rebuild" switch --flake "$SCRIPT_DIR#mac" --impure; then
        log_success "Personal configuration applied"
    else
        log_error "Failed to apply personal configuration"
        log_step "You may need to manually resolve file conflicts"
        return 1
    fi
}

# =============================================================================
# Verification Functions
# =============================================================================

verify_system_config() {
    log_info "Verifying system configuration from machines/default.nix..."

    local checks_passed=0
    local checks_total=0

    # Check 1: Verify nix-darwin is active
    checks_total=$((checks_total + 1))
    if [[ -f "/run/current-system/sw/bin/darwin-rebuild" ]] || command -v darwin-rebuild &>/dev/null; then
        log_success "✓ nix-darwin system is active"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "⚠ nix-darwin system may not be fully activated"
    fi

    # Check 2: Verify Nix flakes are enabled (from machines/default.nix)
    checks_total=$((checks_total + 1))
    if nix show-config 2>/dev/null | grep -q "experimental-features.*flakes"; then
        log_success "✓ Nix flakes enabled"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "⚠ Nix flakes may not be enabled"
    fi

    # Check 3: Verify Homebrew is available (needed for machines/default.nix casks)
    checks_total=$((checks_total + 1))
    if command -v brew &>/dev/null || [[ -d "/opt/homebrew" ]] || [[ -d "/usr/local/Homebrew" ]]; then
        log_success "✓ Homebrew available"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "⚠ Homebrew not found - casks from machines/default.nix won't install until Homebrew is installed"
    fi

    # Check 4: Verify dock settings can be read (indicates system.defaults is accessible)
    checks_total=$((checks_total + 1))
    if command -v defaults &>/dev/null; then
        local dock_autohide
        dock_autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo "")
        if [[ -n "$dock_autohide" ]]; then
            log_success "✓ System preferences accessible (dock autohide: $dock_autohide)"
            checks_passed=$((checks_passed + 1))
        else
            log_info "ℹ Dock settings will be applied on next login"
        fi
    fi

    # Summary
    echo ""
    if [[ $checks_passed -eq $checks_total ]]; then
        log_success "All configuration checks passed ($checks_passed/$checks_total)"
    else
        log_info "Configuration checks: $checks_passed/$checks_total passed"
        if [[ $checks_passed -lt $checks_total ]]; then
            log_step "Some settings may require a logout/login to take effect"
            log_step "Homebrew casks will install automatically on next darwin-rebuild"
        fi
    fi
}

# =============================================================================
# Post-Install Setup
# =============================================================================

start_karabiner_elements() {
    log_info "Starting Karabiner Elements..."

    # Check if Karabiner Elements is installed
    if [[ ! -d "/Applications/Karabiner-Elements.app" ]]; then
        log_warning "Karabiner Elements not found - it may not be installed yet"
        return 0
    fi

    # Check if Karabiner Elements is already running
    if pgrep -f "Karabiner-Elements" > /dev/null; then
        log_success "Karabiner Elements is already running"
        return 0
    fi

    # Start Karabiner Elements
    if open -a "Karabiner-Elements" 2>/dev/null; then
        log_success "Karabiner Elements started"
    else
        log_warning "Failed to start Karabiner Elements"
        log_step "You can start it manually: open -a Karabiner-Elements"
    fi
}

reload_ghostty_theme() {
    log_section "Reloading Ghostty Theme"

    # Check if Ghostty is installed
    if [[ ! -d "/Applications/Ghostty.app" ]]; then
        log_warning "Ghostty not found - it may not be installed yet"
        log_step "Ghostty will pick up the theme configuration when it's installed"
        return 0
    fi

    # Check if Ghostty is running
    if ! pgrep -f "Ghostty" > /dev/null; then
        log_info "Ghostty is not running - opening a new window"
        if open -a "Ghostty" 2>/dev/null; then
            log_success "Ghostty opened with new theme configuration"
        else
            log_warning "Failed to open Ghostty"
        fi
        return 0
    fi

    log_info "Reloading Ghostty configuration to apply new theme..."
    log_step "Using Cmd+Shift+, to reload config dynamically"

    # Reload Ghostty configuration using AppleScript
    # This sends Cmd+Shift+, which is the default reload config shortcut
    if osascript -e '
        tell application "Ghostty"
            if it is running then
                activate
                delay 0.25
                tell application "System Events"
                    keystroke "," using {shift down, command down}
                end tell
            end if
        end tell
    ' 2>/dev/null; then
        log_success "Ghostty configuration reloaded - theme should be applied"
        log_step "If the theme didn't change, you may need to restart Ghostty"
    else
        log_warning "Failed to reload Ghostty configuration programmatically"
        log_step "You can reload manually: Press Cmd+Shift+, in Ghostty"
        log_step "Or restart Ghostty: open -a Ghostty"
    fi
}

show_final_steps() {
    log_header "System Installation Complete"

    echo ""
    log_success "Nix-darwin system has been installed and configured!"
    echo ""

    log_info "Configuration Summary:"
    echo ""
    log_step "✓ machines/default.nix - System settings (dock, keyboard, firewall, Homebrew casks)"
    log_step "✓ home.nix - User configuration (shell, tools, themes)"
    log_step "✓ modules/ - Modular configuration (software, languages, theme, tools)"
    echo ""

    log_info "What was configured from machines/default.nix:"
    log_step "  • macOS system preferences (dock autohide, keyboard settings)"
    log_step "  • Homebrew taps and casks (installing automatically via homebrew module)"
    log_step "  • Nix settings (flakes enabled, trusted users)"
    log_step "  • Application firewall configuration"
    log_step "  • Display resolution (if supported Mac model)"
    echo ""

    log_warning "IMPORTANT: Start a new terminal session to load shell changes!"
    log_step "Close this terminal and open a new one, or run: exec zsh"
    echo ""

    log_info "Note: Some settings may require a logout/login to take full effect:"
    log_step "  • Dock settings (autohide, size, persistent apps)"
    log_step "  • Keyboard preferences (function keys)"
    log_step "  • Default browser settings"
    log_step "  • Homebrew casks will install automatically on next darwin-rebuild"
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

    # Phase 2: Install Homebrew
    log_section "Installing Homebrew"
    install_homebrew

    # Phase 3: Generate local configuration
    log_section "Local Configuration"
    generate_local_config

    # Phase 4: Build and activate system
    log_section "Building System"
    build_system

    # Activate system - continue even if there are file conflicts
    if ! activate_system; then
        log_warning "System activation had issues, but continuing setup..."
        log_step "You may need to manually resolve file conflicts later"
    fi

    # Phase 4.5: Install Node.js LTS
    log_section "Node.js Setup"
    install_node_lts || log_warning "Node.js LTS installation skipped or failed"

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

        # Apply personal config - continue even if there are issues
        if ! apply_personal_config; then
            log_warning "Personal configuration had issues, but continuing setup..."
            log_step "You can apply it later with: darwin-rebuild switch --flake .#mac --impure"
        fi
    fi

    # Phase 6: Start Karabiner Elements
    log_section "Starting Karabiner Elements"
    start_karabiner_elements

    # Phase 7: Reload Ghostty theme dynamically
    reload_ghostty_theme

    # Done - show summary and offer onboarding
    show_final_steps
    run_onboarding

    # Final message - don't block on user input to avoid hanging processes
    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${GREEN}  🎉 Setup complete! Start a new terminal to use your shell.${RESET}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    # Exit cleanly instead of exec zsh to avoid hanging processes
    # User should start a new terminal session themselves
    exit 0
}

main "$@"
