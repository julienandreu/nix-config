# Customization Guide

This guide explains how to customize your setup while keeping it in sync with the team configuration.

## Using Your Existing Configs

If you already have configuration files in `~/.config/`, the Nix setup will install the default configs. To use your existing configs instead:

### Option 1: Symlink Your Configs (Recommended)

If your configs are in a dotfiles repository, symlink them:

```bash
# Backup the Nix-managed configs
mv ~/.config/starship ~/.config/starship.nix-backup
mv ~/.config/nvim ~/.config/nvim.nix-backup

# Symlink your existing configs
ln -s ~/path/to/your/dotfiles/.config/starship ~/.config/starship
ln -s ~/path/to/your/dotfiles/.config/nvim ~/.config/nvim
```

**Note**: After running `./update.sh`, you may need to recreate the symlinks if Nix overwrites them.

### Option 2: Override in Your Local Module

Create a local override file:

```bash
mkdir -p ~/.config/nix-config/local
```

Create `~/.config/nix-config/local/override.nix`:

```nix
{ config, pkgs, ... }:

{
  # Override starship to use your existing config
  programs.starship.settings = builtins.fromTOML (
    builtins.readFile "${config.home.homeDirectory}/.config/starship/starship.toml"
  );
}
```

Then import it in `home.nix`:

```nix
imports = [
  ./modules/software.nix
  ./modules/languages.nix
  ./modules/tools.nix
  ./modules/theme.nix
  ./local/override.nix  # Add this line
];
```

### Option 3: Fork and Modify

Fork the repository and modify the config files directly. This works best if you want to contribute your changes back to the team.

## Personal Additions

To add personal packages without affecting the team config:

1. Create `~/.config/nix-config/local/packages.nix`:

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Your personal packages here
    htop
    tree
  ];
}
```

2. Import it in `home.nix` (as shown above).

## Git Configuration

Git configuration (user name/email) is managed via `~/.config/nix-config/local/secrets.nix`. This file is automatically created from `secrets/template.nix` during setup. Edit it and rebuild to apply changes:

```bash
darwin-rebuild switch --flake ~/.config/nix-config#macbook
```

## Updating Without Losing Customizations

When you run `./update.sh`, it will:
- Pull latest changes from the repo
- Update packages
- Rebuild configuration

If you've symlinked your configs, you may need to recreate the symlinks after updates. Consider adding this to your `~/.zshrc`:

```bash
# Recreate symlinks after Nix updates
if [ -d ~/.config/nix-config ]; then
  # Add your symlink recreation commands here
fi
```

## Best Practices

1. **Keep team configs in sync**: Don't modify files in `modules/` or `configs/` directly unless contributing to the team
2. **Use local overrides**: Put personal customizations in `local/` directory
3. **Document changes**: If you add something useful, consider contributing it back
4. **Test updates**: Before running `./update.sh` on a Monday, test on Friday afternoon

