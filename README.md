# Company Engineering Workstation Setup

This repository contains the Nix configuration for setting up engineering workstations. It provides a reproducible, version-controlled development environment that can be set up in minutes.

## 🎯 What This Does

This configuration automatically sets up:

- **Terminal & Shell**: Ghostty, Zsh with Starship prompt
- **Development Tools**: Git, GitHub CLI, AWS CLI, Docker
- **Languages**: Node.js/TypeScript, Rust, Python
- **CLI Tools**: Neovim, Zoxide, Ripgrep, fd, fzf, jq
- **GUI Apps**: Cursor, Slack, Linear, Docker, Karabiner Elements (via nix-darwin's Homebrew module)
- **System**: Karabiner Elements for keyboard customization
- **Theme**: Catppuccin Mocha throughout

## 📋 Prerequisites

Before running the setup, ensure you have:

- ✅ macOS (Apple Silicon or Intel)
- ✅ Admin access to your machine
- ✅ Company Google account (for SSO apps)
- ✅ Company AWS account (IAM user or SSO)
- ✅ Company GitHub account (organization access)

## 🚀 Quick Start (For New Hires)

### Step 1: Get Your Accounts

Make sure you have received:
- [ ] Google account (email@company.com)
- [ ] GitHub organization invite
- [ ] AWS IAM user credentials or SSO access

### Step 2: Run Setup

Clone this repository and run the setup script:

```bash
git clone git@github.com:yourcompany/nix-config.git ~/.config/nix-config
cd ~/.config/nix-config
./setup.sh
```

Or if you prefer a one-liner:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yourcompany/nix-config/main/setup.sh)
```

The setup script will:
1. Install Nix (if not already installed)
2. Bootstrap nix-darwin
3. Install all packages and tools
4. **Interactively prompt you for:**
   - Your name and email (for Git)
   - Your Google account (for SSO apps)
   - Generate SSH key for GitHub
   - Configure AWS (optional)
5. Automatically create your personal configuration file
6. Open applications and guide you through final setup steps

### Step 3: Complete Setup

The setup script will interactively prompt you for:
- **Your name and email** (for Git configuration)
- **Your Google account** (for SSO applications)
- **SSH key generation** (automatically generates and helps you add it to GitHub)
- **AWS configuration** (optional, can be done later)

The script will:
- ✅ Generate an SSH key automatically
- ✅ Open GitHub in your browser to add the SSH key
- ✅ Create your personal configuration file automatically
- ✅ Guide you through signing into applications

### Step 4: Complete Manual Steps

Some applications require manual sign-in:

1. **GitHub**: Run `gh auth login` (or follow the prompt during setup)
2. **AWS**: Run `aws configure sso` (or `aws configure` for IAM)
3. **Cursor**: Open and sign in with Google SSO
4. **Linear**: Open and sign in with Google SSO
5. **Slack**: Open and sign in with Google SSO
6. **Docker**: Open Docker Desktop and start the daemon

### Step 5: Verify Installation

```bash
# Check that key tools are installed
which nvim git gh aws docker

# Check language versions
node --version
rustc --version
python3 --version

# Check shell configuration
echo $SHELL
starship --version
```

## 📁 Project Structure

```
nix-config/
├── flake.nix              # Main Nix flake entry point
├── home.nix               # Home Manager configuration
├── setup.sh               # Initial setup script
├── update.sh              # Update script
├── machines/
│   └── default.nix        # nix-darwin system configuration
├── modules/
│   ├── software.nix       # Applications and tools
│   ├── languages.nix      # Programming languages
│   ├── tools.nix          # CLI utilities
│   └── theme.nix          # Visual theming
├── configs/
│   ├── starship/          # Starship prompt config
│   ├── nvim/              # Neovim configuration
│   ├── ghostty/           # Ghostty terminal config
│   ├── karabiner/         # Karabiner Elements config
│   └── git/               # Git configuration
└── secrets/
    └── template.env       # Secrets template
```

## 🔄 Daily Usage

### Updating Your Configuration

When the team adds new tools or updates configurations:

```bash
cd ~/.config/nix-config
./update.sh
```

This will:
- Pull latest changes from the repository
- Update all Nix packages
- Rebuild your configuration
- Update Homebrew apps

### Adding New Software

To add new software to the team configuration:

1. Edit the appropriate module file in `modules/`
2. Commit and push your changes
3. Create a PR for review
4. After merge, team members run `./update.sh`

### Customizing Your Setup

Personal customizations should go in `~/.config/local/` to avoid conflicts with company config. The configuration will automatically use your existing configs if they exist in `~/.config/`.

## 🛠️ Troubleshooting

### Nix build fails

```bash
# Clear the Nix store cache
nix-collect-garbage -d

# Rebuild
cd ~/.config/nix-config
darwin-rebuild switch --flake .#macbook
```

### Application not found after install

Make sure your shell has been restarted or source your profile:

```bash
source ~/.zshrc
# Or restart your terminal
```

### Homebrew cask installation fails

```bash
# Update Homebrew
brew update

# Try installing manually
brew install --cask <app-name>
```

### Git configuration not applied

Check that your secrets file is properly sourced:

```bash
source ~/.company-secrets
# Then rebuild
darwin-rebuild switch --flake ~/.config/nix-config#macbook
```

## 🔐 Security Notes

- Never commit `~/.company-secrets` or any files with real credentials
- The `secrets/template.env` file is safe to commit (it's just a template)
- AWS credentials are stored in `~/.aws/` (not managed by Nix)
- GitHub tokens are managed by `gh auth` (stored securely by GitHub CLI)

## 📚 Resources

- [Nix Reference Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Darwin](https://github.com/LnL7/nix-darwin)
- [Zero to Nix](https://zero-to-nix.com/)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to improve this setup.

## 📞 Support

- **Slack**: #engineering-setup
- **Issues**: Create an issue in this repository
- **Documentation**: [Confluence link]

---

**Note**: This configuration is designed for macOS. Linux support can be added by creating additional machine configurations.

