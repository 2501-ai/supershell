#!/bin/bash
# Bash-specific integration

if [ -n "$BASH_VERSION" ]; then
    bind '"\e[C": forward-char'
    
    trap '_cleanup_debounce' SIGINT
    bind -x '"\C-m": "_cleanup_debounce; READLINE_LINE=$READLINE_LINE\n"'
    bind '"\e[A": "_select_prev_suggestion"'  # Up arrow
    bind '"\e[B": "_select_next_suggestion"'  # Down arrow
    
    _bash_complete() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            READLINE_LINE="$CURRENT_SUGGESTION"
            READLINE_POINT=${#READLINE_LINE}
        fi
    }

    bind -x '"\t": _bash_complete'
    info "registered bash hooks"
fi