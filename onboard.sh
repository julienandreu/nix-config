#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Onboarding Script - Post-Installation Software Setup
# =============================================================================
# This script guides users through setting up all installed applications
# in the correct order after the initial Nix configuration is applied.
# =============================================================================

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"

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
# Detection Functions - Check if steps are already completed
# =============================================================================

is_chrome_configured() {
    # Check if Chrome is set as default browser
    defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -q "com.google.chrome" || return 1
    # Check if Chrome is installed
    [[ -d "/Applications/Google Chrome.app" ]] || return 1
}

is_github_configured() {
    # Check if GitHub CLI is authenticated
    command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1
}

is_ssh_key_configured() {
    # Check if SSH key exists and is added to GitHub
    [[ -f "$SSH_KEY_PATH" ]] || return 1
    # Test SSH connection to GitHub
    ssh -T git@github.com -o StrictHostKeyChecking=no -o ConnectTimeout=5 &>/dev/null
}

is_1password_configured() {
    # Check if 1Password is installed and running
    [[ -d "/Applications/1Password.app" ]] && pgrep -f "1Password" >/dev/null 2>&1
}

is_aws_console_configured() {
    # Check if AWS credentials directory exists (indicates AWS Console has been used)
    [[ -d "$HOME/.aws" ]] && [[ -f "$HOME/.aws/credentials" || -f "$HOME/.aws/config" ]]
}

is_aws_cli_configured() {
    # Check if AWS CLI is configured and can list identities
    command -v aws &>/dev/null && aws sts get-caller-identity &>/dev/null 2>&1
}

is_cursor_configured() {
    # Check if Cursor is installed and has extensions installed
    local cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    [[ -x "$cursor_cli" ]] || return 1
    # Check if at least some expected extensions are installed
    local ext_count
    ext_count=$("$cursor_cli" --list-extensions 2>/dev/null | wc -l | tr -d ' ')
    [[ $ext_count -gt 0 ]]
}

is_linear_configured() {
    # Check if Linear is installed
    [[ -d "/Applications/Linear.app" ]]
}

is_slack_configured() {
    # Check if Slack is installed
    [[ -d "/Applications/Slack.app" ]]
}

# =============================================================================
# Step 1: Google Chrome Setup
# =============================================================================

setup_chrome() {
    log_step_header "1" "Google Chrome - Default Browser & Account Setup"

    # Check if already configured
    if is_chrome_configured; then
        log_success "Chrome appears to be already configured!"
        log_info "Chrome is set as default browser and installed."
        if ! confirm_step "Do you want to reconfigure Chrome?"; then
            log_info "Skipping Chrome setup"
            return 0
        fi
    fi

    log_info "Google Chrome will be configured as your default browser."
    log_info "You'll sign in with your Saris Google account."
    echo ""

    # Set Chrome as default browser via command line
    log_action "Setting Chrome as default browser..."
    if [[ -d "/Applications/Google Chrome.app" ]]; then
        # Open Chrome first to ensure it's registered as a browser
        open -a "Google Chrome" "chrome://settings/people" --args --make-default-browser 2>/dev/null || true
        sleep 2
        log_success "Chrome opened and set as default browser candidate"
    else
        log_warning "Google Chrome not found. It may still be installing."
        wait_for_user "Press Enter after Chrome is installed..."
        open -a "Google Chrome" "chrome://settings/people" --args --make-default-browser 2>/dev/null || true
    fi

    echo ""
    log_info "Please complete the following in Chrome:"
    echo ""
    log_step "1. Sign in with your ${BOLD}$USER@saris.ai${RESET} account"
    log_step "2. When prompted, click ${BOLD}'Turn on sync'${RESET} to sync Chrome with Google"
    log_step "3. Go to Settings → On startup → Open a specific page"
    log_step "4. Add ${BOLD}https://mail.google.com/${RESET} as your startup page"
    echo ""
    log_info "Opening Chrome startup settings..."
    sleep 1
    # Use AppleScript to open chrome:// internal URLs
    osascript -e 'tell application "Google Chrome" to open location "chrome://settings/onStartup"' 2>/dev/null || true

    wait_for_completion "Press Enter when Chrome is signed in and configured..."

    # Verify Chrome is default
    if defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -q "com.google.chrome"; then
        log_success "Chrome is configured as default browser"
    else
        log_warning "You may need to confirm Chrome as default browser in System Settings"
        log_step "Go to: System Settings → Desktop & Dock → Default web browser"
    fi

    log_success "Step 1 complete: Chrome is set up!"
}

# =============================================================================
# Step 2: GitHub Web Login & CLI Authentication
# =============================================================================

setup_github() {
    log_step_header "2" "GitHub - Web Login & CLI Authentication"

    # Check if already configured
    if is_github_configured; then
        log_success "GitHub CLI appears to be already authenticated!"
        if ! confirm_step "Do you want to re-authenticate GitHub?"; then
            log_info "Skipping GitHub setup"
            return 0
        fi
    fi

    log_info "You'll sign into GitHub via the web browser first,"
    log_info "then authenticate the GitHub CLI (gh) for terminal access."
    echo ""

    # Open GitHub login page
    log_action "Opening GitHub login page..."
    open "https://github.com/login"

    echo ""
    log_info "Please sign in to GitHub in Chrome."
    log_step "Use your existing GitHub account"
    log_step "Complete any 2FA verification if prompted"

    wait_for_completion "Press Enter when you're signed into GitHub..."

    log_success "GitHub web login complete"
    echo ""

    # Authenticate GitHub CLI
    log_action "Now authenticating GitHub CLI..."
    echo ""

    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found. Please restart your terminal and try again."
        return 1
    fi

    if gh auth status &>/dev/null; then
        log_success "GitHub CLI is already authenticated"
    else
        log_info "The GitHub CLI will now authenticate via your browser."
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

    log_success "Step 2 complete: GitHub is set up!"
}

# =============================================================================
# Step 3: SSH Key Generation for GitHub
# =============================================================================

setup_ssh_key() {
    log_step_header "3" "SSH Key - Generate & Add to GitHub"

    # Check if already configured
    if is_ssh_key_configured; then
        log_success "SSH key appears to be already configured and working!"
        log_info "SSH key exists and GitHub connection is working."
        if ! confirm_step "Do you want to regenerate or reconfigure SSH key?"; then
            log_info "Skipping SSH key setup"
            return 0
        fi
    fi

    log_info "An SSH key provides secure authentication for Git operations."
    echo ""

    local generate_new=true

    if [[ -f "$SSH_KEY_PATH" ]]; then
        log_warning "An SSH key already exists at: $SSH_KEY_PATH"
        if ! confirm_step "Generate a new SSH key?"; then
            generate_new=false
            log_info "Using existing SSH key"
        fi
    fi

    if [[ "$generate_new" == true ]]; then
        # Get email for key
        local git_email
        git_email=$(git config --global user.email 2>/dev/null || echo "")

        if [[ -z "$git_email" ]]; then
            echo ""
            read -rp "   Enter your email for the SSH key: " git_email
        fi

        log_action "Generating SSH key..."
        ssh-keygen -t ed25519 -C "$git_email" -f "$SSH_KEY_PATH" -N ""
        log_success "SSH key generated at $SSH_KEY_PATH"

        # Configure SSH
        configure_ssh_config
    fi

    # Copy key to clipboard and add to GitHub
    echo ""
    log_action "Copying SSH public key to clipboard..."
    if command -v pbcopy &>/dev/null; then
        pbcopy < "$SSH_KEY_PATH.pub"
        log_success "SSH public key copied to clipboard"
    fi

    echo ""
    echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
    echo -e "${BOLD}Your SSH public key:${RESET}"
    echo ""
    cat "$SSH_KEY_PATH.pub"
    echo ""
    echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
    echo ""

    # Add key to GitHub
    log_action "Opening GitHub SSH settings..."
    open "https://github.com/settings/ssh/new"

    echo ""
    log_info "Add your SSH key to GitHub:"
    log_step "1. The key is already copied to your clipboard"
    log_step "2. Paste it into the ${BOLD}'Key'${RESET} field"
    log_step "3. Give it a title (e.g., 'MacBook - Saris')"
    log_step "4. Click ${BOLD}'Add SSH key'${RESET}"

    wait_for_completion "Press Enter when you've added the key to GitHub..."

    # Test SSH connection
    test_github_ssh

    # Test with a private repository
    test_private_repo

    log_success "Step 3 complete: SSH key is configured!"
}

configure_ssh_config() {
    local ssh_config="$HOME/.ssh/config"

    if [[ -f "$ssh_config" ]] && grep -q "Host github.com" "$ssh_config"; then
        log_info "SSH config already contains GitHub entry"
        return 0
    fi

    mkdir -p "$HOME/.ssh"
    cat >> "$ssh_config" <<EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    IdentitiesOnly yes
EOF
    chmod 600 "$ssh_config"
    log_success "SSH config updated for GitHub"
}

test_github_ssh() {
    log_action "Testing SSH connection to GitHub..."
    echo ""

    # Add GitHub to known hosts if not present
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null || true

    local ssh_output
    ssh_output=$(ssh -T git@github.com 2>&1 || true)

    if echo "$ssh_output" | grep -q "successfully authenticated"; then
        log_success "SSH authentication successful!"
        echo "$ssh_output" | grep "successfully authenticated" | sed 's/^/   /'
    else
        log_warning "SSH test output:"
        echo "$ssh_output" | head -3 | sed 's/^/   /'
    fi
}

test_private_repo() {
    echo ""
    log_info "Let's test access to a private repository."
    echo ""

    # Get user's repos via gh CLI
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        log_action "Fetching your private repositories..."

        local repos
        repos=$(gh repo list --visibility private --limit 5 --json nameWithOwner --jq '.[].nameWithOwner' 2>/dev/null || echo "")

        if [[ -n "$repos" ]]; then
            echo ""
            log_info "Your private repositories:"
            echo "$repos" | head -5 | while read -r repo; do
                log_step "$repo"
            done
            echo ""

            local first_repo
            first_repo=$(echo "$repos" | head -1)

            log_action "Testing SSH access to: $first_repo"
            if git ls-remote "git@github.com:$first_repo.git" HEAD &>/dev/null; then
                log_success "SSH access to private repository confirmed!"
            else
                log_warning "Could not access repository via SSH. You may need to wait a moment."
            fi
        else
            log_info "No private repositories found, or gh CLI not authenticated."
            log_step "You can test manually: git clone git@github.com:your-org/your-repo.git"
        fi
    else
        log_info "GitHub CLI not authenticated. Skipping private repo test."
        log_step "You can test manually: git clone git@github.com:your-org/your-repo.git"
    fi
}

# =============================================================================
# Step 4: 1Password Setup
# =============================================================================

setup_1password() {
    log_step_header "4" "1Password - Password Manager Setup"

    # Check if already configured
    if is_1password_configured; then
        log_success "1Password appears to be already configured!"
        log_info "1Password is installed and running."
        if ! confirm_step "Do you want to reconfigure 1Password?"; then
            log_info "Skipping 1Password setup"
            return 0
        fi
    fi

    log_info "1Password is your secure password manager."
    log_info "You'll sign in with your Google account."
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
    log_info "Please complete the 1Password setup:"
    log_step "1. Click ${BOLD}'Sign in'${RESET}"
    log_step "2. Choose ${BOLD}'Sign in with Google'${RESET}"
    log_step "3. Use your ${BOLD}$USER@saris.ai${RESET} account"
    log_step "4. Complete any additional verification"
    log_step "5. Set up biometric unlock (Touch ID) if prompted"

    wait_for_completion "Press Enter when 1Password is set up..."

    log_success "Step 4 complete: 1Password is configured!"
}

# =============================================================================
# Step 5: AWS Console Setup
# =============================================================================

setup_aws_console() {
    log_step_header "5" "AWS Console - Sign In & 2FA Setup"

    # Check if already configured
    if is_aws_console_configured; then
        log_success "AWS Console appears to be already configured!"
        log_info "AWS credentials directory exists."
        if ! confirm_step "Do you want to reconfigure AWS Console?"; then
            log_info "Skipping AWS Console setup"
            return 0
        fi
    fi

    log_info "You'll sign into AWS Console and set up 2FA for security."
    echo ""

    log_action "Opening AWS Console..."
    open "https://console.aws.amazon.com/"

    echo ""
    log_info "Please complete the AWS Console setup:"
    log_step "1. Sign in with your AWS credentials"
    log_step "   (Check 1Password for your credentials)"
    log_step "2. If this is your first login, you may need to set a password"
    echo ""
    log_info "Setting up 2FA (MFA):"
    log_step "3. Click your username in the top right → ${BOLD}'Security credentials'${RESET}"
    log_step "4. Scroll to ${BOLD}'Multi-factor authentication (MFA)'${RESET}"
    log_step "5. Click ${BOLD}'Assign MFA device'${RESET}"
    log_step "6. Choose ${BOLD}'Authenticator app'${RESET}"
    log_step "7. Use 1Password or your authenticator app to scan the QR code"
    log_step "8. Enter two consecutive codes to verify"

    wait_for_completion "Press Enter when AWS Console is signed in and 2FA is configured..."

    log_success "Step 5 complete: AWS Console is configured!"
}

# =============================================================================
# Step 6: AWS CLI Configuration
# =============================================================================

setup_aws_cli() {
    log_step_header "6" "AWS CLI - Command Line Configuration"

    log_info "The AWS CLI allows you to interact with AWS from the terminal."
    log_info "You'll configure it using credentials from 1Password."
    echo ""

    if ! command -v aws &>/dev/null; then
        log_error "AWS CLI not found. Please restart your terminal and try again."
        return 1
    fi

    # Check if already configured
    if is_aws_cli_configured; then
        log_success "AWS CLI appears to be already configured and working!"
        log_info "AWS CLI can authenticate successfully."
        if ! confirm_step "Would you like to reconfigure AWS credentials?"; then
            log_info "Skipping AWS CLI setup"
            return 0
        fi
    fi

    echo ""
    log_info "First, get your AWS credentials from 1Password:"
    log_step "1. Open ${BOLD}1Password${RESET}"
    log_step "2. Search for your AWS credentials"
    log_step "3. Copy the ${BOLD}Access Key ID${RESET} and ${BOLD}Secret Access Key${RESET}"
    echo ""

    wait_for_user "Press Enter when you have your AWS credentials ready..."

    log_action "Configuring AWS CLI..."
    echo ""
    log_info "You'll be prompted to enter:"
    log_step "AWS Access Key ID (from 1Password)"
    log_step "AWS Secret Access Key (from 1Password)"
    log_step "Default region name (e.g., 'us-east-1' or 'eu-west-1')"
    log_step "Default output format (press Enter for 'json')"
    echo ""

    aws configure

    echo ""
    # Verify configuration
    if aws sts get-caller-identity &>/dev/null; then
        log_success "AWS CLI configured and authenticated!"
        log_info "Your AWS identity:"
        aws sts get-caller-identity --output table 2>/dev/null | sed 's/^/   /'
    else
        log_warning "AWS CLI configured but authentication could not be verified"
        log_step "Check your credentials and try: aws sts get-caller-identity"
    fi

    log_success "Step 6 complete: AWS CLI is configured!"
}

# =============================================================================
# Step 7: Cursor Setup
# =============================================================================

setup_cursor() {
    log_step_header "7" "Cursor - AI Code Editor Setup"

    # Check if already configured
    if is_cursor_configured; then
        log_success "Cursor appears to be already configured!"
        log_info "Cursor is installed and has extensions installed."
        if ! confirm_step "Do you want to reconfigure Cursor or reinstall extensions?"; then
            log_info "Skipping Cursor setup"
            return 0
        fi
    fi

    log_info "Cursor is your AI-powered code editor."
    log_info "You'll sign in with your Google account."
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
    log_info "Please complete the Cursor setup:"
    log_step "1. When Cursor opens, click ${BOLD}'Sign In'${RESET}"
    log_step "2. Choose ${BOLD}'Sign in with Google'${RESET}"
    log_step "3. Use your ${BOLD}$USER@saris.ai${RESET} account"
    log_step "4. Grant any permissions requested"
    echo ""
    log_info "Optional: Import settings from VS Code if prompted"

    wait_for_completion "Press Enter when Cursor is signed in..."

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
    fi

    echo ""
    log_success "Step 7 complete: Cursor is configured!"
}

# =============================================================================
# Step 8: Linear Setup
# =============================================================================

setup_linear() {
    log_step_header "8" "Linear - Project Management Setup"

    # Check if already configured
    if is_linear_configured; then
        log_success "Linear appears to be already installed!"
        log_info "Linear application is installed."
        if ! confirm_step "Do you want to reconfigure Linear?"; then
            log_info "Skipping Linear setup"
            return 0
        fi
    fi

    log_info "Linear is your project and issue tracking tool."
    log_info "You'll sign in with your Google account."
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
    log_info "Please complete the Linear setup:"
    log_step "1. Click ${BOLD}'Sign in'${RESET} or ${BOLD}'Continue with Google'${RESET}"
    log_step "2. Use your ${BOLD}$USER@saris.ai${RESET} account"
    log_step "3. You should automatically join the Saris workspace"
    log_step "4. Configure notifications if prompted"

    wait_for_completion "Press Enter when Linear is signed in..."

    log_success "Step 8 complete: Linear is configured!"
}

# =============================================================================
# Step 9: Slack Setup
# =============================================================================

setup_slack() {
    log_step_header "9" "Slack - Team Communication Setup"

    # Check if already configured
    if is_slack_configured; then
        log_success "Slack appears to be already installed!"
        log_info "Slack application is installed."
        if ! confirm_step "Do you want to reconfigure Slack?"; then
            log_info "Skipping Slack setup"
            return 0
        fi
    fi

    log_info "Slack is your team communication platform."
    log_info "You'll sign in with your Google account."
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
    log_info "Please complete the Slack setup:"
    log_step "1. Click ${BOLD}'Sign in to Slack'${RESET}"
    log_step "2. Enter your workspace URL or email"
    log_step "3. Choose ${BOLD}'Sign in with Google'${RESET}"
    log_step "4. Use your ${BOLD}$USER@saris.ai${RESET} account"
    log_step "5. Allow the app to open when prompted"
    echo ""
    log_info "Tip: Pin Slack to your Dock for easy access"

    wait_for_completion "Press Enter when Slack is signed in..."

    log_success "Step 9 complete: Slack is configured!"
}

# =============================================================================
# Completion
# =============================================================================

show_completion() {
    log_header "🎉 Onboarding Complete!"

    echo ""
    log_success "All applications have been configured!"
    echo ""

    echo -e "${BOLD}Summary of what's set up:${RESET}"
    echo ""
    log_step "✓ Google Chrome - Default browser, synced with Google"
    log_step "✓ GitHub - Web login + CLI (gh) authenticated"
    log_step "✓ SSH Key - Generated and added to GitHub"
    log_step "✓ 1Password - Password manager configured"
    log_step "✓ AWS Console - Signed in with 2FA"
    log_step "✓ AWS CLI - Credentials configured"
    log_step "✓ Cursor - AI code editor ready"
    log_step "✓ Linear - Project management connected"
    log_step "✓ Slack - Team communication active"
    echo ""

    echo -e "${BOLD}Quick reference commands:${RESET}"
    echo ""
    log_step "AWS identity:    ${CYAN}aws sts get-caller-identity${RESET}"
    log_step "GitHub status:   ${CYAN}gh auth status${RESET}"
    log_step "Test SSH:        ${CYAN}ssh -T git@github.com${RESET}"
    log_step "Update system:   ${CYAN}darwin-rebuild switch --flake .#mac --impure${RESET}"
    echo ""

    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${GREEN}  Welcome to Saris! Your workstation is ready. 🚀${RESET}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_header "🖥️  Saris Workstation Onboarding"

    echo ""
    log_info "This script will guide you through setting up all your applications."
    log_info "Each step builds on the previous one, so please complete them in order."
    echo ""

    # Check what's already configured
    local configured_steps=()
    local pending_steps=()

    if is_chrome_configured; then
        configured_steps+=("1. Google Chrome ✓")
    else
        pending_steps+=("1. Google Chrome (default browser + account sync)")
    fi

    if is_github_configured; then
        configured_steps+=("2. GitHub ✓")
    else
        pending_steps+=("2. GitHub (web login + CLI authentication)")
    fi

    if is_ssh_key_configured; then
        configured_steps+=("3. SSH Key ✓")
    else
        pending_steps+=("3. SSH Key (for secure Git access)")
    fi

    if is_1password_configured; then
        configured_steps+=("4. 1Password ✓")
    else
        pending_steps+=("4. 1Password (password manager)")
    fi

    if is_aws_console_configured; then
        configured_steps+=("5. AWS Console ✓")
    else
        pending_steps+=("5. AWS Console (cloud access + 2FA)")
    fi

    if is_aws_cli_configured; then
        configured_steps+=("6. AWS CLI ✓")
    else
        pending_steps+=("6. AWS CLI (command line tools)")
    fi

    if is_cursor_configured; then
        configured_steps+=("7. Cursor ✓")
    else
        pending_steps+=("7. Cursor (AI code editor)")
    fi

    if is_linear_configured; then
        configured_steps+=("8. Linear ✓")
    else
        pending_steps+=("8. Linear (project management)")
    fi

    if is_slack_configured; then
        configured_steps+=("9. Slack ✓")
    else
        pending_steps+=("9. Slack (team communication)")
    fi

    # Show status summary
    if [[ ${#configured_steps[@]} -gt 0 ]]; then
        log_success "Already configured (${#configured_steps[@]}/9):"
        for step in "${configured_steps[@]}"; do
            log_step "$step"
        done
        echo ""
    fi

    if [[ ${#pending_steps[@]} -gt 0 ]]; then
        log_info "Pending setup (${#pending_steps[@]}/9):"
        for step in "${pending_steps[@]}"; do
            log_step "$step"
        done
        echo ""
    else
        log_success "All steps are already configured!"
        echo ""
        if ! confirm_step "Do you want to reconfigure any steps?"; then
            log_info "Onboarding complete. Exiting."
            exit 0
        fi
    fi

    if ! confirm_step "Ready to begin?"; then
        log_info "Onboarding cancelled. Run this script again when ready."
        exit 0
    fi

    # Run each step in order
    setup_chrome
    setup_github
    setup_ssh_key
    setup_1password
    setup_aws_console
    setup_aws_cli
    setup_cursor
    setup_linear
    setup_slack

    # Show completion message
    show_completion
}

main "$@"

