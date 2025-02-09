#!/bin/bash
set +m  # Disable job control
# Avoid using set -e, this might cause the terminal to exit on any error (from this plugin or any other)

# Main entry point that sources all other files
SCRIPT_DIR="${0:A:h}"  # For Zsh
if [ -z "$SCRIPT_DIR" ]; then  # Fallback for Bash
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &> /dev/null && pwd)"
fi

# Check if we're running in Warp terminal
if [ "$TERM_PROGRAM" = "WarpTerminal" ]; then
    info "[MAIN] Running in Warp terminal - skipping SuperShell initialization"
    return 0
fi

# Check if we're running in Bash
if [ -n "$BASH_VERSION" ]; then
    echo "[MAIN] Running in Bash mode"
    # Enable command-oriented history
    bind 'set enable-bracketed-paste off'
fi



# Source configuration first
source "$SCRIPT_DIR/config.sh"

# Source utilities
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/ansi.sh"
source "$SCRIPT_DIR/utils/sys_info.sh"

# Source logger first and configure it
source "$SCRIPT_DIR/core/logger.sh"

# Initialize logger silently
_logger_init >/dev/null 2>&1

# Source update checker
source "$SCRIPT_DIR/shell/zsh_upgrade.sh"

# Source core functionality
source "$SCRIPT_DIR/core/suggestion.sh"
source "$SCRIPT_DIR/core/debounce.sh"
source "$SCRIPT_DIR/core/display.sh"

# Source shell integrations
source "$SCRIPT_DIR/shell/common.sh"

# Source the appropriate shell integration based on the current shell
if [ -n "$ZSH_VERSION" ]; then
    source "$SCRIPT_DIR/shell/zsh_integration.sh"
elif [ -n "$BASH_VERSION" ]; then
    source "$SCRIPT_DIR/shell/bash_integration.sh"
fi

# Log startup
info "[MAIN] Supershell started"