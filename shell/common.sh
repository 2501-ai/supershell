#!/bin/bash
# Common shell functionality

echo "[COMMON] Initializing common shell functions..."

_universal_complete() {
    echo "[COMMON] Universal complete triggered"
    local current_word="$1"
    local cursor_pos="$2"
    
    echo "[COMMON] Current word: $current_word"
    echo "[COMMON] Cursor position: $cursor_pos"
    
    if [ -z "$current_word" ]; then
        echo "[COMMON] Empty input, clearing display"
        clear_lines
        CURRENT_SUGGESTION=""
        return
    fi
    
    if [ ${#current_word} -ge 2 ]; then
        echo "[COMMON] Word length sufficient, fetching suggestions"
        _debounced_suggest "$current_word"
    fi
}

_execute_suggestion() {
    if [ -n "$CURRENT_SUGGESTION" ]; then
        clear_lines
        eval "$CURRENT_SUGGESTION"
        CURRENT_SUGGESTION=""
    fi
}