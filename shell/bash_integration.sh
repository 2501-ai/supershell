#!/bin/bash
# Bash-specific integration

if [ -n "$BASH_VERSION" ]; then
    # Handle CTRL+C
    trap '_cleanup_debounce' SIGINT
    
    # Enable forward-char for proper cursor movement
    bind '"\e[C": forward-char'
    
    # Navigation functions
    _bash_select_next() {
        _select_next_suggestion
        # Refresh the display
        _display_suggestions "$LAST_RESPONSE"
    }
    
    _bash_select_prev() {
        _select_prev_suggestion
        # Refresh the display
        _display_suggestions "$LAST_RESPONSE"
    }
    
    # Execute the currently selected suggestion
    _bash_execute() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            READLINE_LINE="$CURRENT_SUGGESTION"
            READLINE_POINT=${#READLINE_LINE}
        fi
    }
    
    # Completion function that triggers suggestions
    _bash_completion() {
        _universal_complete "$READLINE_LINE" "$READLINE_POINT"
    }
    
    # Handle Enter key
    _bash_accept_line() {
        _cleanup_debounce
        READLINE_LINE="$READLINE_LINE"
    }
    
    # Bind keys
    bind -x '"\e[A": _bash_select_prev'    # Up arrow
    bind -x '"\e[B": _bash_select_next'    # Down arrow
    bind -x '"\t": _bash_execute'          # Tab key to execute suggestion
    bind -x '"\C-m": _bash_accept_line'    # Enter key
    
    # Add readline hook for completion
    bind -x '"\C-i": _bash_completion'
    
    # Enable continuous completion as you type
    bind 'set show-all-if-ambiguous on'
    bind 'set completion-ignore-case on'
    bind 'set menu-complete-display-prefix on'
fi