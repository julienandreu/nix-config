#!/usr/bin/env bash

# =============================================================================
# Nix Configuration Bootstrap Installer
# =============================================================================
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
#
# Or with wget:
#   /bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
#
# =============================================================================

set -euo pipefail

# Configuration
REPO_URL="https://github.com/julienandreu/nix-config.git"
INSTALL_DIR="${NIX_CONFIG_DIR:-$HOME/.nix-config}"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' BLUE='' BOLD='' RESET=''
fi

log_info() { echo -e "${BLUE}ℹ${RESET}  $1"; }
log_success() { echo -e "${GREEN}✓${RESET}  $1"; }
log_error() { echo -e "${RED}✗${RESET}  $1"; }

# =============================================================================
# Main
# =============================================================================

echo ""
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Nix Configuration Installer${RESET}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Check macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This installer is designed for macOS only"
    exit 1
fi

# Check for git
if ! command -v git &>/dev/null; then
    log_info "Git not found, installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo "Please wait for Xcode Command Line Tools to install, then run this script again."
    exit 1
fi

# Clone or update repository
if [[ -d "$INSTALL_DIR" ]]; then
    log_info "Existing installation found at $INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    if [[ -d ".git" ]]; then
        log_info "Updating repository..."
        git pull --quiet
        log_success "Repository updated"
    fi
else
    log_info "Cloning repository to $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    log_success "Repository cloned"
    cd "$INSTALL_DIR"
fi

# Run setup
log_info "Starting setup..."
echo ""

exec bash "$INSTALL_DIR/setup.sh"
