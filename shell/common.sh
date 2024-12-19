#!/bin/bash
# Common shell functionality

_universal_complete() {
    local current_word="$1"
    local cursor_pos="$2"
    
    if [ -z "$current_word" ]; then
        clear_lines
        CURRENT_SUGGESTION=""
        return
    fi
    
    if [ ${#current_word} -ge 2 ]; then
        _start_loading
        _debounced_suggest "$current_word"
        _stop_loading
    fi
}

_execute_suggestion() {
    if [ -n "$CURRENT_SUGGESTION" ]; then
        clear_lines
        eval "$CURRENT_SUGGESTION"
        CURRENT_SUGGESTION=""
    fi
}