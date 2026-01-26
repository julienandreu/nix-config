#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Onboarding Script - Post-Installation Application Setup
# =============================================================================
# This script guides users through setting up installed applications after
# the initial Nix configuration is applied via setup.sh.
#
# Note: Git, SSH keys, and basic system configuration are handled by setup.sh
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

# =============================================================================
# Logging Functions
# =============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' BOLD='' DIM='' RESET=''
fi

log_header() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${BLUE}  $1${RESET}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

log_step_header() {
    local step_num="$1"
    local step_title="$2"
    local total_steps="${3:-9}"
    echo ""
    echo -e "${BOLD}${MAGENTA}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
    echo -e "${BOLD}${MAGENTA}┃  Step ${step_num}/${total_steps}: ${step_title}${RESET}"
    echo -e "${BOLD}${MAGENTA}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
    echo ""
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
    echo -e "   ${DIM}→${RESET}  $1"
}

log_action() {
    echo -e "   ${CYAN}▸${RESET}  ${BOLD}$1${RESET}"
}

wait_for_user() {
    local message="${1:-Press Enter to continue...}"
    echo ""
    read -rp "   ${message} "
}

wait_for_completion() {
    local message="${1:-Press Enter when you\'ve completed this step...}"
    echo ""
    echo -e "   ${YELLOW}⏳${RESET} ${message}"
    read -rp "   "
}

confirm_step() {
    local message="$1"
    echo ""
    read -rp "   $message (Y/n): " response
    [[ -z "$response" || "$response" =~ ^[Yy]$ ]]
}

# =============================================================================
# Detection Functions
# =============================================================================

is_chrome_configured() {
    [[ -d "/Applications/Google Chrome.app" ]] && \
    defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -q "com.google.chrome"
}

is_github_configured() {
    command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1
}

is_1password_configured() {
    [[ -d "/Applications/1Password.app" ]]
}

is_aws_configured() {
    [[ -d "$HOME/.aws" ]] && [[ -f "$HOME/.aws/credentials" || -f "$HOME/.aws/config" ]]
}

is_cursor_configured() {
    local cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    [[ -x "$cursor_cli" ]] && [[ $("$cursor_cli" --list-extensions 2>/dev/null | wc -l | tr -d ' ') -gt 0 ]]
}

is_docker_configured() {
    [[ -d "/Applications/Docker.app" ]] && pgrep -f "Docker Desktop" >/dev/null 2>&1
}

is_linear_configured() {
    [[ -d "/Applications/Linear.app" ]]
}

is_slack_configured() {
    [[ -d "/Applications/Slack.app" ]]
}

is_ai_assistants_configured() {
    command -v claude &>/dev/null && command -v codex &>/dev/null
}

# =============================================================================
# Step 1: Chrome Setup
# =============================================================================

setup_chrome() {
    log_step_header "1" "Google Chrome - Default Browser Setup"

    if is_chrome_configured; then
        log_success "Chrome is already configured as default browser!"
        if ! confirm_step "Do you want to reconfigure Chrome?"; then
            log_info "Skipping Chrome setup"
            return 0
        fi
    fi

    log_info "Setting up Chrome as your default browser."
    echo ""

    log_action "Opening Chrome..."
    if [[ -d "/Applications/Google Chrome.app" ]]; then
        open -a "Google Chrome" "chrome://settings/people" --args --make-default-browser 2>/dev/null || true
        sleep 2
        log_success "Chrome opened"
    else
        log_warning "Chrome not found. It may still be installing."
        wait_for_user "Press Enter after Chrome is installed..."
        open -a "Google Chrome" 2>/dev/null || true
    fi

    echo ""
    log_info "Please complete Chrome setup:"
    log_step "1. Sign in with your Google account (if desired)"
    log_step "2. Set Chrome as default browser if prompted"
    log_step "3. Configure any sync or startup preferences"

    wait_for_completion

    if defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -q "com.google.chrome"; then
        log_success "Chrome is configured as default browser"
    else
        log_warning "Chrome may not be set as default"
        log_step "Go to: System Settings → Desktop & Dock → Default web browser"
    fi

    log_success "Step 1 complete!"
}

# =============================================================================
# Step 2: GitHub CLI Setup
# =============================================================================

setup_github() {
    log_step_header "2" "GitHub CLI - Authentication"

    if is_github_configured; then
        log_success "GitHub CLI is already authenticated!"
        if ! confirm_step "Do you want to re-authenticate?"; then
            log_info "Skipping GitHub CLI setup"
            return 0
        fi
    fi

    log_info "Authenticating GitHub CLI for terminal access."
    log_info "Note: SSH keys were configured during setup.sh"
    echo ""

    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found. Restart your terminal and try again."
        return 1
    fi

    if gh auth status &>/dev/null; then
        log_success "GitHub CLI is already authenticated"
    else
        log_info "Authenticating GitHub CLI via web browser..."
        echo ""
        log_step "Choose: ${BOLD}GitHub.com${RESET}"
        log_step "Choose: ${BOLD}HTTPS${RESET} (recommended)"
        log_step "Choose: ${BOLD}Login with a web browser${RESET}"
        echo ""

        gh auth login --web --git-protocol https

        if gh auth status &>/dev/null; then
            log_success "GitHub CLI authenticated successfully"
        else
            log_warning "GitHub CLI authentication may need to be completed"
        fi
    fi

    log_success "Step 2 complete!"
}

# =============================================================================
# Step 3: 1Password Setup
# =============================================================================

setup_1password() {
    log_step_header "3" "1Password - Password Manager Setup"

    if is_1password_configured; then
        log_success "1Password is already installed!"
        if ! confirm_step "Do you want to reconfigure 1Password?"; then
            log_info "Skipping 1Password setup"
            return 0
        fi
    fi

    log_info "1Password is your secure password and secrets manager."
    echo ""

    log_action "Opening 1Password..."
    if [[ -d "/Applications/1Password.app" ]]; then
        open -a "1Password"
    else
        log_warning "1Password not found. It may still be installing."
        wait_for_user "Press Enter after 1Password is installed..."
        open -a "1Password"
    fi

    echo ""
    log_info "Please complete 1Password setup:"
    log_step "1. Sign in to your 1Password account"
    log_step "2. Set up browser extensions (if desired)"
    log_step "3. Configure unlock preferences"
    log_step "4. Enable SSH key management (optional but recommended)"

    wait_for_completion
    log_success "Step 3 complete!"
}

# =============================================================================
# Step 4: AWS Setup
# =============================================================================

setup_aws() {
    log_step_header "4" "AWS - Console & CLI Setup"

    if is_aws_configured; then
        log_success "AWS appears to be configured!"
        if ! confirm_step "Do you want to reconfigure AWS?"; then
            log_info "Skipping AWS setup"
            return 0
        fi
    fi

    log_info "Setting up AWS Console access and CLI credentials."
    echo ""

    # AWS Console
    log_action "Opening AWS Console..."
    open "https://aws.amazon.com/console/"

    echo ""
    log_info "AWS Console Setup:"
    log_step "1. Sign in with your AWS account"
    log_step "2. Enable MFA/2FA if required by your organization"
    log_step "3. Verify you have access to your resources"

    wait_for_completion

    # AWS CLI
    log_action "Configuring AWS CLI..."
    echo ""

    if ! command -v aws &>/dev/null; then
        log_error "AWS CLI not found. Restart your terminal and try again."
        return 1
    fi

    log_info "AWS CLI Configuration Methods:"
    log_step "Option 1: ${BOLD}aws configure${RESET} - Interactive setup"
    log_step "Option 2: ${BOLD}aws configure sso${RESET} - For SSO/IAM Identity Center"
    log_step "Option 3: Manually edit ~/.aws/credentials and ~/.aws/config"
    echo ""

    if confirm_step "Do you want to run 'aws configure' now?"; then
        aws configure
        log_success "AWS CLI configuration complete"
    else
        log_info "Skipping AWS CLI configuration"
        log_step "Configure later with: aws configure"
    fi

    # Test AWS CLI
    if aws sts get-caller-identity &>/dev/null 2>&1; then
        log_success "AWS CLI is working!"
        aws sts get-caller-identity | grep -E "(UserId|Account|Arn)" | sed 's/^/   /'
    else
        log_warning "AWS CLI test failed - you may need to configure credentials"
    fi

    log_success "Step 4 complete!"
}

# =============================================================================
# Step 5: Cursor Setup
# =============================================================================

setup_cursor() {
    log_step_header "5" "Cursor - AI Code Editor Setup"

    if is_cursor_configured; then
        log_success "Cursor appears to be configured with extensions!"
        if ! confirm_step "Do you want to reconfigure Cursor?"; then
            log_info "Skipping Cursor setup"
            return 0
        fi
    fi

    log_info "Cursor is an AI-powered code editor based on VS Code."
    echo ""

    log_action "Opening Cursor..."
    if [[ -d "/Applications/Cursor.app" ]]; then
        open -a "Cursor"
    else
        log_warning "Cursor not found. It may still be installing."
        wait_for_user "Press Enter after Cursor is installed..."
        open -a "Cursor"
    fi

    echo ""
    log_info "Please complete Cursor setup:"
    log_step "1. Sign in to Cursor (if you have an account)"
    log_step "2. Configure your AI model preferences"
    log_step "3. Install any additional extensions you need"
    echo ""
    log_info "Note: Nix config provides default settings and extensions."
    log_info "Your custom settings are merged automatically."

    wait_for_completion

    # Install Cursor extensions
    log_info "Installing Cursor extensions..."
    echo ""

    # List of extensions to install
    local extensions=(
        # Language Support
        "rust-lang.rust-analyzer"                    # Rust
        "jnoortheen.nix-ide"                        # Nix
        "hashicorp.terraform"                        # Terraform
        "charliermarsh.ruff"                         # Python (Ruff)
        "ms-python.python"                           # Python (base support)

        # Code Quality & Formatting
        "dbaeumer.vscode-eslint"                     # ESLint
        "esbenp.prettier-vscode"                     # Prettier
        "EditorConfig.EditorConfig"                  # EditorConfig

        # Productivity
        "wayou.vscode-todo-highlight"                # TODO Highlight

        # DevOps & Tools
        "ms-azuretools.vscode-docker"                 # Docker
        "redhat.vscode-yaml"                         # YAML
        "bradlc.vscode-tailwindcss"                  # Tailwind CSS
        "mikestead.dotenv"                           # DotENV
        "tamasfe.even-better-toml"                   # TOML
        "YoavBls.pretty-ts-errors"                   # Pretty TS Errors
    )

    # Check if cursor CLI is available
    local cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    if [[ ! -x "$cursor_cli" ]]; then
        log_warning "Cursor CLI not found at expected location"
        log_step "Extensions will need to be installed manually from the Extensions view"
        log_step "Search for each extension by name in Cursor's Extensions panel"
    else
        # Add cursor CLI to PATH for this session
        export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"

        local installed=0
        local failed=0

        # Wait a moment for Cursor to be fully ready
        log_info "Waiting for Cursor to be ready..."
        sleep 3

        for ext in "${extensions[@]}"; do
            "$cursor_cli" --install-extension "$ext" --force
        done

        echo ""
        log_success "Cursor CLI available (run 'cursor' in terminal)"
    fi

    log_success "Step 5 complete!"
}

# =============================================================================
# Step 6: Docker Desktop Setup
# =============================================================================

setup_docker() {
    log_step_header "6" "Docker Desktop - Container Platform Setup"

    if is_docker_configured; then
        log_success "Docker Desktop is already running!"
        if ! confirm_step "Do you want to reconfigure Docker?"; then
            log_info "Skipping Docker setup"
            return 0
        fi
    fi

    log_info "Docker Desktop provides container management for development."
    echo ""

    log_action "Opening Docker Desktop..."
    if [[ -d "/Applications/Docker.app" ]]; then
        open -a "Docker"
    else
        log_warning "Docker Desktop not found. It may still be installing."
        wait_for_user "Press Enter after Docker Desktop is installed..."
        open -a "Docker"
    fi

    echo ""
    log_info "Please complete Docker Desktop setup:"
    log_step "1. Accept the service agreement"
    log_step "2. Wait for Docker daemon to start (watch the menu bar icon)"
    log_step "3. Sign in with Docker Hub account (optional)"
    log_step "4. Configure resource limits if needed (Settings → Resources)"

    wait_for_completion

    # Test Docker
    if command -v docker &>/dev/null; then
        log_action "Testing Docker..."
        if docker ps &>/dev/null; then
            log_success "Docker is running and accessible"
        else
            log_warning "Docker command available but daemon may not be ready"
            log_step "Wait a moment for Docker to finish starting"
        fi
    else
        log_warning "Docker CLI not yet available"
        log_step "Restart your terminal to load Docker CLI"
    fi

    log_success "Step 6 complete!"
}

# =============================================================================
# Step 7: Linear Setup
# =============================================================================

setup_linear() {
    log_step_header "7" "Linear - Project Management Setup"

    if is_linear_configured; then
        log_success "Linear is already installed!"
        if ! confirm_step "Do you want to reconfigure Linear?"; then
            log_info "Skipping Linear setup"
            return 0
        fi
    fi

    log_info "Linear is your project and issue tracking tool."
    echo ""

    log_action "Opening Linear..."
    if [[ -d "/Applications/Linear.app" ]]; then
        open -a "Linear"
    else
        log_warning "Linear not found. It may still be installing."
        wait_for_user "Press Enter after Linear is installed..."
        open -a "Linear"
    fi

    echo ""
    log_info "Please complete Linear setup:"
    log_step "1. Sign in to your workspace"
    log_step "2. Configure your teams and projects"
    log_step "3. Set up keyboard shortcuts (optional)"

    wait_for_completion
    log_success "Step 7 complete!"
}

# =============================================================================
# Step 8: Slack Setup
# =============================================================================

setup_slack() {
    log_step_header "8" "Slack - Team Communication Setup"

    if is_slack_configured; then
        log_success "Slack is already installed!"
        if ! confirm_step "Do you want to reconfigure Slack?"; then
            log_info "Skipping Slack setup"
            return 0
        fi
    fi

    log_info "Slack is your team communication platform."
    echo ""

    log_action "Opening Slack..."
    if [[ -d "/Applications/Slack.app" ]]; then
        open -a "Slack"
    else
        log_warning "Slack not found. It may still be installing."
        wait_for_user "Press Enter after Slack is installed..."
        open -a "Slack"
    fi

    echo ""
    log_info "Please complete Slack setup:"
    log_step "1. Sign in to your workspace(s)"
    log_step "2. Configure notification preferences"
    log_step "3. Set your status and profile"

    wait_for_completion
    log_success "Step 8 complete!"
}

# =============================================================================
# Step 9: AI Assistants Setup
# =============================================================================

setup_ai_assistants() {
    log_step_header "9" "AI Coding Assistants - Claude Code & Codex"

    if is_ai_assistants_configured; then
        log_success "AI assistants are already configured!"
        if ! confirm_step "Do you want to reconfigure AI assistants?"; then
            log_info "Skipping AI assistants setup"
            return 0
        fi
    fi

    log_info "Claude Code and Codex are AI coding assistants in your terminal."
    echo ""

    # Claude Code
    if command -v claude &>/dev/null; then
        log_success "Claude Code is installed"

        if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
            echo ""
            log_action "Setting up Claude Code API key..."
            log_step "Get your API key from: https://console.anthropic.com/settings/keys"
            echo ""

            if confirm_step "Do you have an Anthropic API key?"; then
                echo ""
                read -rsp "   Enter your Anthropic API key: " api_key
                echo ""

                if [[ -n "$api_key" ]]; then
                    # Add to secrets.nix if it exists
                    local secrets_file="$HOME/.config/nix-config/local/secrets.nix"
                    if [[ -f "$secrets_file" ]]; then
                        # Check if ANTHROPIC_API_KEY already exists
                        if grep -q "ANTHROPIC_API_KEY" "$secrets_file"; then
                            log_info "ANTHROPIC_API_KEY already in secrets.nix - update it manually if needed"
                        else
                            echo "" >> "$secrets_file"
                            echo "  # Anthropic API Key for Claude Code" >> "$secrets_file"
                            echo "  home.sessionVariables.ANTHROPIC_API_KEY = \"$api_key\";" >> "$secrets_file"
                            log_success "Added ANTHROPIC_API_KEY to secrets.nix"
                        fi
                    else
                        # Add to .zshrc as fallback
                        if ! grep -q "ANTHROPIC_API_KEY" "$HOME/.zshrc" 2>/dev/null; then
                            echo "" >> "$HOME/.zshrc"
                            echo "export ANTHROPIC_API_KEY=\"$api_key\"" >> "$HOME/.zshrc"
                            log_success "Added ANTHROPIC_API_KEY to .zshrc"
                        fi
                    fi
                    export ANTHROPIC_API_KEY="$api_key"
                fi
            else
                log_info "Skipping Claude Code API key setup"
                log_step "Set it later: export ANTHROPIC_API_KEY=your-key"
            fi
        else
            log_success "ANTHROPIC_API_KEY is already set"
        fi
    else
        log_warning "Claude Code not installed. Check that it's in modules/software.nix"
    fi

    echo ""

    # Codex
    if command -v codex &>/dev/null; then
        log_success "Codex is installed"

        if [[ -z "${OPENAI_API_KEY:-}" ]]; then
            echo ""
            log_action "Setting up Codex (OpenAI) API key..."
            log_step "Get your API key from: https://platform.openai.com/api-keys"
            echo ""

            if confirm_step "Do you have an OpenAI API key?"; then
                echo ""
                read -rsp "   Enter your OpenAI API key: " api_key
                echo ""

                if [[ -n "$api_key" ]]; then
                    # Add to secrets.nix if it exists
                    local secrets_file="$HOME/.config/nix-config/local/secrets.nix"
                    if [[ -f "$secrets_file" ]]; then
                        # Check if OPENAI_API_KEY already exists
                        if grep -q "OPENAI_API_KEY" "$secrets_file"; then
                            log_info "OPENAI_API_KEY already in secrets.nix - update it manually if needed"
                        else
                            echo "" >> "$secrets_file"
                            echo "  # OpenAI API Key for Codex" >> "$secrets_file"
                            echo "  home.sessionVariables.OPENAI_API_KEY = \"$api_key\";" >> "$secrets_file"
                            log_success "Added OPENAI_API_KEY to secrets.nix"
                        fi
                    else
                        # Add to .zshrc as fallback
                        if ! grep -q "OPENAI_API_KEY" "$HOME/.zshrc" 2>/dev/null; then
                            echo "" >> "$HOME/.zshrc"
                            echo "export OPENAI_API_KEY=\"$api_key\"" >> "$HOME/.zshrc"
                            log_success "Added OPENAI_API_KEY to .zshrc"
                        fi
                    fi
                    export OPENAI_API_KEY="$api_key"
                fi
            else
                log_info "Skipping Codex API key setup"
                log_step "Set it later: export OPENAI_API_KEY=your-key"
            fi
        else
            log_success "OPENAI_API_KEY is already set"
        fi
    else
        log_warning "Codex not installed. Check that it's in modules/software.nix"
    fi

    echo ""
    log_info "Usage:"
    log_step "• claude - Start Claude Code assistant"
    log_step "• codex - Start OpenAI Codex assistant"
    echo ""
    log_warning "Restart your terminal to load environment variables"

    wait_for_completion
    log_success "Step 9 complete!"
}

# =============================================================================
# Show Completion Message
# =============================================================================

show_completion() {
    log_header "🎉 Application Setup Complete!"

    echo ""
    log_success "All applications have been configured!"
    echo ""

    log_info "Your development environment is now ready to use."
    echo ""

    log_info "Quick reference:"
    log_step "• Chrome: Your default browser"
    log_step "• GitHub CLI: gh auth status"
    log_step "• 1Password: Password manager"
    log_step "• AWS: aws sts get-caller-identity"
    log_step "• Cursor: AI code editor (cursor command)"
    log_step "• Docker: Container platform (docker ps)"
    log_step "• Linear: Project management"
    log_step "• Slack: Team communication"
    log_step "• AI Assistants: claude, codex commands"
    echo ""

    log_info "Useful commands:"
    log_step "• ./update.sh - Update your Nix configuration"
    log_step "• darwin-rebuild switch --flake .#mac - Rebuild system manually"
    log_step "• brew upgrade - Update Homebrew packages"
    echo ""

    log_warning "Start a new terminal session to load all environment changes!"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_header "📱 Application Onboarding"

    echo ""
    log_info "This wizard will help you set up your installed applications."
    echo ""
    log_info "Applications to configure:"
    log_step "1. Google Chrome (default browser)"
    log_step "2. GitHub CLI (gh authentication)"
    log_step "3. 1Password (password manager)"
    log_step "4. AWS (console & CLI)"
    log_step "5. Cursor (AI code editor)"
    log_step "6. Docker Desktop (containers)"
    log_step "7. Linear (project management)"
    log_step "8. Slack (team communication)"
    log_step "9. AI Assistants (Claude Code & Codex)"
    echo ""

    log_warning "Note: Git and SSH keys were configured during setup.sh"
    log_step "If you need to reconfigure those, run: ./setup.sh"
    echo ""

    # Check status
    local configured_count=0
    is_chrome_configured && ((configured_count++)) || true
    is_github_configured && ((configured_count++)) || true
    is_1password_configured && ((configured_count++)) || true
    is_aws_configured && ((configured_count++)) || true
    is_cursor_configured && ((configured_count++)) || true
    is_docker_configured && ((configured_count++)) || true
    is_linear_configured && ((configured_count++)) || true
    is_slack_configured && ((configured_count++)) || true
    is_ai_assistants_configured && ((configured_count++)) || true

    if [[ $configured_count -eq 9 ]]; then
        log_success "All applications appear to be configured already!"
        echo ""
        if ! confirm_step "Do you want to run through setup again?"; then
            log_info "Onboarding complete. Exiting."
            exit 0
        fi
    else
        log_info "Detected: $configured_count/9 applications already configured"
    fi

    if ! confirm_step "Ready to begin?"; then
        log_info "Onboarding cancelled. Run this script again when ready."
        exit 0
    fi

    # Run each step
    setup_chrome
    setup_github
    setup_1password
    setup_aws
    setup_cursor
    setup_docker
    setup_linear
    setup_slack
    setup_ai_assistants

    # Show completion message
    show_completion
}

main "$@"
