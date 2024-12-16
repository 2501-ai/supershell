#!/bin/bash
# Bash-specific integration

if [ -n "$BASH_VERSION" ]; then
    bind '"\e[C": forward-char'
    
    trap '_cleanup_debounce' SIGINT
    bind -x '"\C-m": "_cleanup_debounce; READLINE_LINE=$READLINE_LINE\n"'
    
    _bash_complete() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            _execute_suggestion
        else
            _universal_complete "$READLINE_LINE" "$READLINE_POINT"
        fi
    }
    bind -x '"\t": _bash_complete'
fi