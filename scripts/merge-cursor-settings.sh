#!/usr/bin/env bash
# Merge Cursor settings: Nix defaults + user overrides = final settings.json
# This script intelligently merges Nix-managed defaults with user-editable settings

set -euo pipefail

CURSOR_USER_DIR="${HOME}/Library/Application Support/Cursor/User"
DEFAULTS_FILE="${CURSOR_USER_DIR}/settings.json.defaults"
SETTINGS_FILE="${CURSOR_USER_DIR}/settings.json"
BACKUP_FILE="${CURSOR_USER_DIR}/settings.json.backup"

# Ensure Cursor User directory exists
mkdir -p "${CURSOR_USER_DIR}"

# Check if defaults file exists (managed by Nix)
if [[ ! -f "${DEFAULTS_FILE}" ]]; then
    echo "Warning: Defaults file not found at ${DEFAULTS_FILE}"
    echo "This is normal on first run. Settings will be created when Nix config is applied."
    exit 0
fi

# Read defaults (from Nix)
DEFAULTS_JSON=$(cat "${DEFAULTS_FILE}")

# If settings.json doesn't exist, just copy defaults
if [[ ! -f "${SETTINGS_FILE}" ]]; then
    echo "${DEFAULTS_JSON}" > "${SETTINGS_FILE}"
    echo "Created ${SETTINGS_FILE} from Nix defaults"
    exit 0
fi

# Read existing user settings
USER_JSON=$(cat "${SETTINGS_FILE}")

# Merge JSON: user settings override defaults
# Using jq to deep merge: user values take precedence
MERGED_JSON=$(echo "${DEFAULTS_JSON}" | jq -s '.[0] * .[1]' - <(echo "${USER_JSON}"))

# Only update if there are actual changes (to avoid unnecessary file writes)
CURRENT_HASH=$(echo "${USER_JSON}" | jq -c . | md5sum | cut -d' ' -f1)
MERGED_HASH=$(echo "${MERGED_JSON}" | jq -c . | md5sum | cut -d' ' -f1)

if [[ "${CURRENT_HASH}" != "${MERGED_HASH}" ]]; then
    # Backup existing settings before updating
    cp "${SETTINGS_FILE}" "${BACKUP_FILE}"

    # Write merged settings
    echo "${MERGED_JSON}" | jq . > "${SETTINGS_FILE}"

    echo "Merged Nix defaults with user settings in ${SETTINGS_FILE}"
    echo "Backup saved to ${BACKUP_FILE}"
else
    echo "Settings already up to date (no new defaults to merge)"
fi
