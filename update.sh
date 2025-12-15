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
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    GREEN='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
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

log_step() {
    echo -e "${DIM}→${RESET}  $1"
}

# =============================================================================
# Update Functions
# =============================================================================

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

rebuild_system() {
    log_info "Rebuilding configuration (requires sudo)..."
    sudo darwin-rebuild switch --flake "$FLAKE" --impure
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

    log_section "Updating Dependencies"
    update_flake_lock

    log_section "Rebuilding System"
    rebuild_system

    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${GREEN}  ✓ Update complete${RESET}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

main "$@"
