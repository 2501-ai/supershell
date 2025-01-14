#!/bin/bash
# Update checker functionality for SuperShell

# ==============================================================================
# Configuration
# ==============================================================================
UPGRADE_STATE_DIR="${HOME}/.config/supershell"
UPGRADE_STATE_FILE="${UPGRADE_STATE_DIR}/upgrade_state"
UPGRADE_LOCK_FILE="${UPGRADE_STATE_DIR}/update.lock"
CURRENT_VERSION=$(cat "${0:A:h}/../version.txt" 2>/dev/null || echo "0.0.0")
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
    # Compare two version strings
    # Returns 0 if $2 is greater than $1
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        local v1=${ver1[i]:-0} v2=${ver2[i]:-0}
        if ((v2 > v1)); then
            return 0
        elif ((v1 > v2)); then
            return 1
        fi
    done
    return 1
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
    
    # Compare versions
    if _version_gt "$CURRENT_VERSION" "$latest_version"; then
        # Update the timestamp even if no update is available
        _update_check_timestamp
        
        # Display update notification
        printf '\033[%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' "$GRAY_90"
        printf '\033[%s┃ \033[38;5;%sNew version available: %s\033[0m\n' "$GRAY_90" "$GREEN" "$latest_version"
        printf '\033[%s┃ Current version: %s\n' "$GRAY_90" "$CURRENT_VERSION"
        printf '\033[%s┃ Update with: git pull origin main\n' "$GRAY_90"
        printf '\033[%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' "$GRAY_90"
    else
        debug "[UPGRADE] No update available"
    fi
}

# ==============================================================================
# Initialize Update Checker
# ==============================================================================

# Run the update check in the background to avoid blocking shell startup
(check_for_updates &) 2>/dev/null