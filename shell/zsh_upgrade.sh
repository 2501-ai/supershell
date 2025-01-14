#!/bin/bash
# Update checker functionality for SuperShell

# ==============================================================================
# Configuration
# ==============================================================================
UPGRADE_STATE_DIR="${HOME}/.config/supershell"
UPGRADE_STATE_FILE="${UPGRADE_STATE_DIR}/upgrade_state"
UPGRADE_LOCK_FILE="${UPGRADE_STATE_DIR}/update.lock"
CURRENT_VERSION=$(cat "${0:A:h}/../VERSION" 2>/dev/null || echo "0.0.0")
GITHUB_API_URL="https://api.github.com/repos/2501-ai/supershell/releases/latest"

# ==============================================================================
# Time Utilities
# ==============================================================================

_current_epoch() {
    zmodload zsh/datetime
    echo $(( EPOCHSECONDS / 60 / 60 / 24 ))  # Returns days since epoch
}

_days_since_last_check() {
    local last_check_days
    last_check_days=$(_get_last_check_timestamp)
    local current_days
    current_days=$(_current_epoch)
    echo $((current_days - last_check_days))
}

# ==============================================================================
# Helper Functions
# ==============================================================================

_ensure_upgrade_state_dir() {
    if [[ ! -d "$UPGRADE_STATE_DIR" ]]; then
        mkdir -p "$UPGRADE_STATE_DIR"
    fi
}

_acquire_lock() {
    if ! mkdir "$UPGRADE_LOCK_FILE" 2>/dev/null; then
        return 1
    fi
    # Remove lock on exit
    trap "command rm -rf '$UPGRADE_LOCK_FILE'" EXIT INT QUIT
    return 0
}

_get_last_check_timestamp() {
    if [[ -f "$UPGRADE_STATE_FILE" ]]; then
        cat "$UPGRADE_STATE_FILE"
    else
        echo "0"
    fi
}

_update_check_timestamp() {
    _current_epoch > "$UPGRADE_STATE_FILE"
}

_fetch_latest_version() {
    # Using curl with silent mode and timeout
    local latest_version
    latest_version=$(curl -s -m 5 "$GITHUB_API_URL" | grep '"tag_name":' | cut -d'"' -f4)
    echo "${latest_version#v}"  # Remove 'v' prefix if present
}

_version_gt() {
     test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

_update_supershell() {
    info "[UPGRADE] Updating SuperShell..."

    # Change to the SuperShell directory
    cd "$SCRIPT_DIR" || {
        error "[UPGRADE] Failed to change to SuperShell directory"
        return 1
    }

    # Fetch and pull updates
    if git pull origin main -q; then
        success "[UPGRADE] SuperShell updated successfully!"
        return 0
    else
        error "[UPGRADE] Failed to update SuperShell"
        return 1
    fi
}
# ==============================================================================
# Main Update Check Function
# ==============================================================================

check_for_updates() {
    info "[UPGRADE] Checking for updates..."
    
    _ensure_upgrade_state_dir
    
    # Get days since last check
    local days_since_check
    days_since_check=$(_days_since_last_check)
    
    # Check if enough time has passed (14 days)
    if [[ $days_since_check -lt 14 ]]; then
        debug "[UPGRADE] Skip check - last check was $days_since_check days ago"
        return 0
    fi
    
    # Try to acquire lock
    if ! _acquire_lock; then
        debug "[UPGRADE] Another update check is in progress"
        return 1
    fi
    
    # Fetch latest version
    local latest_version
    latest_version=$(_fetch_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        warn "[UPGRADE] Failed to fetch latest version"
        return 1
    fi
    debug "[UPGRADE] Latest version: $latest_version"
    debug "[UPGRADE] Current version: $CURRENT_VERSION"

    # Compare versions
    if _version_gt "$latest_version" "$CURRENT_VERSION"; then
        # Update the timestamp even if no update is available
        _update_check_timestamp
        printf '\033[%s\nUpdating SuperShell to version %s\n' "$GRAY_90" "$latest_version.."

        if _update_supershell; then
            # Display update notification
            printf '\033[%s\n' "$GRAY_90"
            printf '\033[%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' "$GRAY_90"
            printf '\033[%s┃ Updated Supershell !\n' "$GRAY_90"
            printf '\033[%s┃ \033[38;5;%sNew version installed : %s\033[0m\n' "$GRAY_90" "$GREEN" "$latest_version"
            printf '\033[%s┃ Please restart your shell to apply the update\n' "$GRAY_90"
            printf '\033[%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' "$GRAY_90"

            # Accept the line
            zle .accept-line
        fi
    else
        debug "[UPGRADE] No update available"
    fi
}

# ==============================================================================
# Initialize Update Checker
# ==============================================================================

# Run the update check in the background to avoid blocking shell startup
(check_for_updates &) 2>/dev/null