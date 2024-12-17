#!/bin/bash
set +m  # Disable job control

# Main entry point that sources all other files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/config.sh"

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