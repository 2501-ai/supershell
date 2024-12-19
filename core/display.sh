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
    _read_suggestions  # Read suggestions from file
    info "Display Suggestions: ${_FETCHED_SUGGESTIONS[*]}"
    info "Suggestions length: ${#_FETCHED_SUGGESTIONS[@]}"
    info "Current suggestion index: $CURRENT_SUGGESTION_INDEX"
    
    # Save cursor position
    printf '\033[s'
    
    clear_lines
    
    # Print the current command line
    # printf '%s' "$READLINE_LINE" 

    if [[ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]]; then
        # Move to next line and display suggestions (to test)
        # printf '\n'
        printf '\033[90m-------SUGGEST MODE--------------\033[0m\n'
        
        # Display remaining suggestions with dots
        local count=0
        local IFS=$'\n'
        for sug in "${_FETCHED_SUGGESTIONS[@]}"; do
            if [ $count -eq "$MAX_SUGGESTIONS" ]; then
                break
            fi

            if [ $count -eq $CURRENT_SUGGESTION_INDEX ]; then
                printf '\033[90m→ %s\033[0m\n' "$sug"
            else 
                printf '\033[90m. %s\033[0m\n' "$sug"
            fi
            count=$((count + 1))
        done

        info "suggestions: ${_FETCHED_SUGGESTIONS[*]}"
        
        # Print execution hint
        printf '\033[38;5;240m[↑↓ to navigate, TAB to select]\033[0m\n'
        # printf '\033[90m-------AGENT MODE----------------\033[0m\n'
        # printf '\033[38;5;240m[Opt+TAB @2501 %s (launch as an agent)]\033[0m' "$prompts"
        
        # Move cursor back to original position 
        printf '\033[%dA\r' "$((count + 1))" # TODO: test with bash
        # printf '\033[%dC' "${#READLINE_LINE}" (useless/noside effect with zsh)
    fi
    
    # Restore cursor position
    printf '\033[u'
    # declare -p | grep _FETCHED_SUGGESTIONS # for debug
}

# Add these navigation functions
_select_next_suggestion() {
    _read_suggestions  # Read suggestions from file
    info "select next"
    # Test if there are suggestions
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % ${#_FETCHED_SUGGESTIONS[@]} ))
        info "current suggestion index: $CURRENT_SUGGESTION_INDEX"
        _display_suggestions
    else
        info "[DISPLAY] No suggestions to navigate"
    fi
}

_select_prev_suggestion() {
    _read_suggestions  # Read suggestions from file
    info "select prev"
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + ${#_FETCHED_SUGGESTIONS[@]}) % ${#_FETCHED_SUGGESTIONS[@]} ))
        _display_suggestions
    else
        info "[DISPLAY] No suggestions to navigate"
    fi
}