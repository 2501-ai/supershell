#!/bin/bash
set +m  # Disable job control
# Avoid using set -e, this might cause the terminal to exit on any error (from this plugin or any other)

# Main entry point that sources all other files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/config.sh"

# Source logger first and configure it
source "$SCRIPT_DIR/core/logger.sh"

# Source utilities
source "$SCRIPT_DIR/utils/ansi.sh"
source "$SCRIPT_DIR/utils/sys_info.sh"

# Source core functionality
source "$SCRIPT_DIR/core/suggestion.sh"
source "$SCRIPT_DIR/core/debounce.sh"
source "$SCRIPT_DIR/core/display.sh"

# Source shell integrations
source "$SCRIPT_DIR/shell/common.sh"
source "$SCRIPT_DIR/shell/bash_integration.sh"
source "$SCRIPT_DIR/shell/zsh_integration.sh"


# Initialize logger silently
_logger_init >/dev/null 2>&1

# Log startup
info "Supershell starting up"

info "Debounce loaded"
info "Delay is $DEBOUNCE_DELAY"
info "Timer PID is $DEBOUNCE_TIMER_PID"