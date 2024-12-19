#!/bin/bash

# Display handling
CURRENT_SUGGESTION_INDEX=0

_show_loading() {
    info "[DISPLAY] Showing loading indicator"
    clear_lines
    printf '%s' "$READLINE_LINE"
    printf '\n%s⋯ fetching suggestions...%s' "$GRAY" "$RESET"
    printf '\033[1A\r'
    printf '\033[%dC' "${#READLINE_LINE}"
}

_display_suggestions() {
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        local count=0
        
        # First, move cursor to start of line
        printf '\r'
        
        # Move down one line and clear everything below
        printf '\n\033[J'
        
        # Print each suggestion
        for sug in "${_FETCHED_SUGGESTIONS[@]}"; do
            if [ $count -eq $CURRENT_SUGGESTION_INDEX ]; then
                printf '\033[90m→ %-40s\033[0m\n' "$sug"
            else 
                printf '\033[90m  %-40s\033[0m\n' "$sug"
            fi
            count=$((count + 1))
        done

        # Print hint
        printf '\033[38;5;240m[↑↓ to navigate, TAB to select]\033[0m'
        
        # Move cursor back to original position
        printf '\033[%dA\r' "$((count + 1))"
        printf '\033[%dC' "${#READLINE_LINE}"
    fi
}

# Add these navigation functions
_select_next_suggestion() {
    _read_suggestions  # Read suggestions from file
    info "select next"
    # Test if there are suggestions
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % ${#_FETCHED_SUGGESTIONS[@]} ))
        info "current suggestion index: $CURRENT_SUGGESTION_INDEX"
        _display_suggestions navigate
    else
        info "[DISPLAY] No suggestions to navigate"
    fi
}

_select_prev_suggestion() {
    _read_suggestions  # Read suggestions from file
    info "select prev"
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + ${#_FETCHED_SUGGESTIONS[@]}) % ${#_FETCHED_SUGGESTIONS[@]} ))
        _display_suggestions navigate
    else
        info "[DISPLAY] No suggestions to navigate"
    fi
}