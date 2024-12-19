#!/bin/bash
# ==============================================================================
# Bash Integration Module
# ==============================================================================
# Provides Bash-specific integration for the shell suggestion system with features:
# - Real-time command suggestions
# - Custom key bindings for navigation
# - Command history integration
# - Readline integration for proper cursor handling
# - Event-driven suggestion updates
#
# Key Bindings:
#   Up/Down    - Navigate through suggestions
#   Tab        - Execute selected suggestion
#   Enter      - Accept current line
#   Ctrl+C     - Cancel current operation
#
# Architecture:
# This module implements the following components:
# 1. Key event handling
# 2. Suggestion navigation
# 3. Command execution
# 4. Display management
# ==============================================================================

info "[BASH] Starting bash integration..."

# ==============================================================================
# Signal Handlers and Initialization
# ==============================================================================

# Handle interrupt signal (Ctrl+C) by cleaning up suggestions
trap '_cleanup_debounce' SIGINT

# Configure readline for proper cursor movement
bind '"\e[C": forward-char'

# ==============================================================================
# State Management
# ==============================================================================

# Control whether completion should be triggered
TRIGGER_COMPLETION=true

# Track the last input line to prevent duplicate processing
LAST_LINE=""

# ==============================================================================
# Input Processing
# ==============================================================================

# Process each character typed by the user
# Arguments:
#   None - Uses READLINE_LINE global variable
# Side effects:
#   - Updates suggestion display
#   - Triggers completion if needed
_bash_self_insert() {
    local line="$READLINE_LINE"
    
    # Only process if the line has changed
    if [[ "$line" != "$LAST_LINE" ]]; then
        info "[BASH] Current line: $line"
        LAST_LINE="$line"
        
        # Trigger suggestions after minimum input length
        if [[ ${#line} -ge 2 ]]; then
            _suppress_job_messages _universal_complete "$line"
        fi
    fi
}

# ==============================================================================
# Navigation Functions
# ==============================================================================

# Select next suggestion without previewing
_bash_select_next() {
    info "[BASH] Selecting next suggestion"
    TRIGGER_COMPLETION=false
    _select_next_suggestion
}

# Select previous suggestion without previewing
_bash_select_prev() {
    info "[BASH] Selecting previous suggestion"
    TRIGGER_COMPLETION=false
    _select_prev_suggestion
}

# ==============================================================================
# Command Execution
# ==============================================================================

# Execute the currently selected suggestion
_bash_execute() {
    _read_suggestions  # Make sure we have latest suggestions
    
    local CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
    if [ -n "$CURRENT_SUGGESTION" ]; then
        # Clear suggestions first
        printf '\033[J'
        printf '\r'
        
        # Set the command and execute
        READLINE_LINE="$CURRENT_SUGGESTION"
        READLINE_POINT=${#READLINE_LINE}
        
        # Reset suggestion state
        _FETCHED_SUGGESTIONS=()
        CURRENT_SUGGESTION_INDEX=0
        LAST_LINE=""
        
        bind '"\C-m": accept-line'
    fi
}

# Handle the Enter key press
_bash_accept_line() {
    # Clear suggestions and reset display
    printf '\033[J'  # Clear everything below the cursor
    printf '\r'      # Move to start of line
    
    # Reset suggestion state
    CURRENT_SUGGESTION_INDEX=0
    LAST_LINE=""
    _FETCHED_SUGGESTIONS=()
    
    # Execute the command
    bind '"\C-m": accept-line'
}

# ==============================================================================
# Key Bindings
# ==============================================================================

# Navigation key bindings
bind -x '"\e[A": _bash_select_prev'    # Up arrow
bind -x '"\e[B": _bash_select_next'    # Down arrow
bind -x '"\t": _bash_execute'          # Tab key

# Allow Enter to work normally when not selecting suggestions
bind '"\C-m": accept-line'

# Configure readline behavior
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set menu-complete-display-prefix on'

# Set up readline key handling
bind 'set keymap emacs'
bind 'set convert-meta on'
bind 'set input-meta on'
bind 'set output-meta on'

# ==============================================================================
# Character Input Handling
# ==============================================================================

# Handle individual character input
# Arguments:
#   $1 - The character that was typed
# Side effects:
#   - Updates readline buffer
#   - Triggers suggestion update
_bash_key_handler() {
    # Insert the typed character at cursor position
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$1${READLINE_LINE:$READLINE_POINT}"
    ((READLINE_POINT++))
    
    # Process the updated line
    _bash_self_insert
}

# Bind common input characters
for c in {a..z}; do
    bind -x "\"$c\": '_bash_key_handler $c'"
    bind -x "\"${c^}\": '_bash_key_handler ${c^}'"  # Capital letters
done

# Bind numeric characters
for n in {0..9}; do
    bind -x "\"$n\": '_bash_key_handler $n'"
done

# Bind special characters
for char in - _ . /; do
    bind -x "\"$char\": '_bash_key_handler $char'"
done

info "[BASH] Integration complete!"
