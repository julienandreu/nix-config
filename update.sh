#!/usr/bin/env bash

set -e

echo "🔄 Updating company configuration..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Pull latest changes
if [ -d ".git" ]; then
    echo "📥 Pulling latest changes..."
    git pull
fi

# Update flake lock
echo "🔒 Updating flake lock..."
nix flake update

# Rebuild and activate
echo "🔨 Rebuilding configuration..."
darwin-rebuild switch --flake "$SCRIPT_DIR#macbook"

# Homebrew apps are managed by nix-darwin, so they'll be updated automatically

echo "✅ Update complete!"

