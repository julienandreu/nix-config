# Personal Nix Configuration

This repository contains my personal Nix configuration for macOS development environments. It provides a reproducible, version-controlled development environment that can be set up in minutes.

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

- macOS (Apple Silicon or Intel)
- Admin access to your machine
- GitHub account

## 🚀 Quick Start

### One-Line Install

Run this command in your terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
```

Or with wget:

```bash
/bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
```

This will:

1. Install Xcode Command Line Tools (if needed)
2. Clone the repository to `~/.nix-config`
3. Install Nix and enable flakes
4. Build and activate the system configuration
5. Guide you through personal setup (Git, SSH keys, etc.)

### Alternative: Manual Installation

If you prefer to clone manually:

```bash
git clone https://github.com/julienandreu/nix-config.git ~/.nix-config
cd ~/.nix-config
./setup.sh
```

### Custom Install Location

You can specify a custom install directory:

```bash
NIX_CONFIG_DIR=~/my-config /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
```

## 📝 What the Setup Does

The setup script will interactively guide you through:

1. **Nix Installation** - Installs Nix package manager and enables flakes
2. **System Configuration** - Builds and activates nix-darwin
3. **Git Setup** - Prompts for your name and email
4. **SSH Key Generation** - Creates an ED25519 key for GitHub and helps you add it
5. **Optional Integrations** - GitHub CLI and AWS CLI configuration

After setup, some applications require manual sign-in:

- **Cursor**: Open and sign in
- **Docker**: Open Docker Desktop and start the daemon
- **Slack/Linear**: Sign in to your workspaces

## ✅ Verify Installation

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
├── install.sh             # One-line bootstrap installer
├── setup.sh               # Full setup script
├── update.sh              # Update script
├── machines/
│   └── default.nix        # nix-darwin system configuration
├── modules/
│   ├── software.nix       # Applications and tools
│   ├── languages.nix      # Programming languages
│   ├── tools.nix          # CLI utilities
│   └── theme.nix          # Visual theming
├── configs/
│   └── nvim/              # Neovim configuration
└── secrets/
    ├── template.env       # Environment secrets template
    └── template.nix       # Nix secrets template
```

## 🔄 Daily Usage

### Updating Your Configuration

When you want to update packages and pull latest changes:

```bash
cd ~/.nix-config
./update.sh
```

This will:

- Pull latest changes from the repository
- Update the flake lock file
- Rebuild your configuration

### Adding New Software

To add new software to your configuration:

1. Edit the appropriate module file in `modules/`
2. Rebuild: `darwin-rebuild switch --flake .#mac`

### Customizing Your Setup

Personal customizations go in `~/.config/nix-config/local/`. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for details.

## 🛠️ Troubleshooting

### Nix build fails

```bash
# Clear the Nix store cache
nix-collect-garbage -d

# Rebuild
darwin-rebuild switch --flake ~/.nix-config#mac
```

### Application not found after install

Restart your terminal or source your profile:

```bash
source ~/.zshrc
```

### Git configuration not applied

Check that your secrets file exists and rebuild:

```bash
ls ~/.config/nix-config/local/secrets.nix
darwin-rebuild switch --flake ~/.nix-config#mac
```

### SSH key not working

Test your GitHub SSH connection:

```bash
ssh -T git@github.com
```

## 🔐 Security Notes

- Never commit `~/.config/nix-config/local/secrets.nix` or files with real credentials
- The `secrets/template.*` files are safe to commit (they're just templates)
- AWS credentials are stored in `~/.aws/` (not managed by Nix)
- GitHub tokens are managed by `gh auth` (stored securely by GitHub CLI)

## 📚 Resources

- [Nix Reference Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Darwin](https://github.com/LnL7/nix-darwin)
- [Zero to Nix](https://zero-to-nix.com/)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)

## 📝 License

This configuration is provided as-is for personal use. Feel free to fork and adapt it to your needs.

---

**Note**: This configuration is designed for macOS. Linux support can be added by creating additional machine configurations.
