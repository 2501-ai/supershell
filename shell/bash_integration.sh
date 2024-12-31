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
    
    # Check for empty buffer first
    if [[ -z "$line" ]]; then
        TRIGGER_COMPLETION=false
        # Restore default key bindings for empty buffer
        bind '"\e[A": previous-history'     # Up arrow
        bind '"\e[B": next-history'         # Down arrow
        return
    fi
    
    # Only process if the line has changed
    if [[ "$line" != "$LAST_LINE" ]]; then
        info "[BASH] Current line: $line"
        LAST_LINE="$line"
        
        # Trigger suggestions after minimum input length
        if [[ ${#line} -ge 2 ]]; then
            _suppress_job_messages _universal_complete "$line"
            # Restore custom key bindings for navigation
            bind -x '"\e[A": _bash_select_prev'    # Up arrow
            bind -x '"\e[B": _bash_select_next'    # Down arrow
        fi
    fi
}

# ==============================================================================
# Navigation Functions
# ==============================================================================

# Select and preview the next suggestion in the list
_bash_select_next() {
    info "[BASH] Selecting next suggestion"
    TRIGGER_COMPLETION=false
    _select_next_suggestion
    
    # Preview the selected suggestion
    local CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
    info "[BASH] Previewing suggestion: $CURRENT_SUGGESTION"
    READLINE_LINE="$CURRENT_SUGGESTION"
    READLINE_POINT=${#READLINE_LINE}
}

# Select and preview the previous suggestion in the list
_bash_select_prev() {
    info "[BASH] Selecting previous suggestion"
    TRIGGER_COMPLETION=false
    _select_prev_suggestion
    
    # Preview the selected suggestion
    local CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
    info "[BASH] Previewing suggestion: $CURRENT_SUGGESTION"
    READLINE_LINE="$CURRENT_SUGGESTION"
    READLINE_POINT=${#READLINE_LINE}
}

# ==============================================================================
# Command Execution
# ==============================================================================

# Execute the currently selected suggestion
# Side effects:
#   - Evaluates the selected command
#   - Clears the suggestion display
#   - Resets suggestion state
_bash_execute() {
    info "[BASH] Executing suggestion"
    local CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
    if [ -n "$CURRENT_SUGGESTION" ]; then
        info "[BASH] Selected suggestion: $CURRENT_SUGGESTION"
        READLINE_LINE="$CURRENT_SUGGESTION"
        READLINE_POINT=${#READLINE_LINE}
        eval "$CURRENT_SUGGESTION"
        CURRENT_SUGGESTION=""
        clear_lines
    else
        info "[BASH] No suggestion to execute"
    fi
}

# Handle the Enter key press
# Side effects:
#   - Cleans up suggestion state
#   - Updates readline buffer
_bash_accept_line() {
    info "[BASH] Accepting line"
    _cleanup_debounce
    READLINE_LINE="$READLINE_LINE"
    info "[BASH] Final line: $READLINE_LINE"
    LAST_LINE=""  # Reset last line on enter
    CURRENT_SUGGESTION_INDEX=0  # Reset index
    info "[BASH] Reset suggestion state"
}

# ==============================================================================
# Key Bindings
# ==============================================================================

# Navigation key bindings
bind -x '"\e[A": _bash_select_prev'    # Up arrow
bind -x '"\e[B": _bash_select_next'    # Down arrow
bind -x '"\t": _bash_execute'          # Tab key
bind -x '"\C-m": _bash_accept_line'    # Enter key

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
