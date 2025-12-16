#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
FLAKE="$SCRIPT_DIR#mac"

# =============================================================================
# Logging Functions
# =============================================================================

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
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

log_step() {
    echo -e "${DIM}→${RESET}  $1"
}

# =============================================================================
# Update Functions
# =============================================================================

ensure_homebrew() {
    # Check if Homebrew is available
    if command -v brew &>/dev/null; then
        return 0
    fi

    # Check common Homebrew locations
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return 0
    fi

    # Install Homebrew if not found
    log_info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for current session
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
}

pull_latest_changes() {
    if [[ ! -d ".git" ]]; then
        log_step "Not a git repository, skipping pull"
        return 0
    fi

    log_info "Pulling latest changes..."
    if git pull --quiet; then
        log_success "Repository updated"
    else
        log_step "Already up to date"
    fi
}

update_flake_lock() {
    log_info "Updating flake lock file..."
    nix flake update
    log_success "Flake lock updated"
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

rebuild_system() {
    # Clean up old backups before rebuild to ensure fresh generation
    cleanup_home_manager_backups
    
    log_info "Rebuilding configuration (requires sudo)..."
    sudo FLAKE_DIR="$SCRIPT_DIR" darwin-rebuild switch --flake "$FLAKE" --impure
    log_success "System rebuilt and activated"
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_header "🔄 Nix Configuration Update"

    cd "$SCRIPT_DIR"

    log_section "Syncing Repository"
    pull_latest_changes

    log_section "Checking Prerequisites"
    ensure_homebrew

    log_section "Updating Dependencies"
    update_flake_lock

    log_section "Rebuilding System"
    rebuild_system

    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${GREEN}  ✓ Update complete${RESET}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    log_warning "Start a new terminal session to load shell changes!"
    log_step "Close this terminal and open a new one, or run: exec zsh"
    echo ""
}

main "$@"
