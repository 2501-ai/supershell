#!/bin/bash
# Common shell functionality

info "[COMMON] Initializing common shell functions..."

_universal_complete() {
    info "[COMMON] Universal complete triggered"
    local current_word="$1"
    # local cursor_pos="$2"

    info "[COMMON] Current word: $current_word"
    # info "[COMMON] Cursor position: $cursor_pos"

    if [ -z "$current_word" ]; then
        # info "[COMMON] Empty input, clearing display"
        clear_lines
        return
    fi

    if [ ${#current_word} -ge 2 ]; then
        # info "[COMMON] Word length sufficient, fetching suggestions"
        _debounced_suggest "$current_word"
    fi
}
