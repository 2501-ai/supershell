#!/bin/bash

# Display handling
CURRENT_SUGGESTION_INDEX=0

SELECTED_COLOR='190m'

if (get_terminal_bg_color | grep -q "ffff"); then
    SELECTED_COLOR='15m'
fi

_show_loading() {
    local -a spinner=('𓃉𓃉𓃉' '𓃉𓃉∘' '𓃉∘°' '∘°∘' '°∘𓃉' '∘𓃉𓃉')
    local i=0

    
    # Save cursor position
    tput sc
    
    clear_lines
    
    # Restore cursor position
    tput rc
    
    # Move down one line
    tput cud1
    tput cr  # Carriage return
    
    # Print spinner and message
    printf "%s𓃉𓃉𓃉" "$GRAY"
    # printf '%s%-3s fetching suggestions...%s' "$GRAY" "${spinner[i]}" "$RESET"

    # Restore cursor position
    tput rc
    
    i=$(( (i + 1) % ${#spinner[@]} ))
    # i=$((i % ${#spinner[@]}))
    # ((i++))
    
    # Clean up after loading is done
    tput rc
}

_display_suggestions() {
    _read_suggestions  # Read suggestions from file
    info "Display Suggestions: ${_FETCHED_SUGGESTIONS[*]}"
    info "Suggestions length: ${#_FETCHED_SUGGESTIONS[@]}"
    info "Current suggestion index: $CURRENT_SUGGESTION_INDEX"
    info "Agentic suggestion: $_AGENTIC_SUGGESTION"
    
    # Save cursor position
    tput sc
    
    clear_lines
    
    # Print the current command line
    # printf '%s' "$READLINE_LINE" 

    if [[ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]]; then
        # Move to next line and display suggestions (to test)
        # printf '\n'
        printf '%s┣━━━ 2501 autocomplete ━━━━━━━━━━━%s\n' "$GRAY" "$RESET"
        
        # Display remaining suggestions with dots
        local count=0
        local IFS=$'\n'
        for sug in "${_FETCHED_SUGGESTIONS[@]}"; do
            if [ $count -eq "$MAX_SUGGESTIONS" ]; then
                break
            fi

            if [ $count -eq $CURRENT_SUGGESTION_INDEX ]; then
                printf '%s┣╸\033[38;5;%s➜ %s%s\n' "$GRAY" "$SELECTED_COLOR" "$sug" "$RESET"
            else 
                printf '%s┣╸ %s%s\n' "$GRAY" "$sug" "$RESET"
            fi
            count=$((count + 1))
        done

        info "suggestions: ${_FETCHED_SUGGESTIONS[*]}"
        
        # Print execution hint
        printf '%s[↑↓ to navigate, Enter ↵ to select]%s\n' "$DARK_GRAY" "$RESET"
        printf '%s %s\n' "$GRAY" "$RESET"
        printf '%s┣━━━ 2501 agent ━━━━━━━━━━━━━━━━━%s\n' "$GRAY" "$RESET"
        printf '%s┗━ \033[38;5;%s@2501 %s%s\n' "$GRAY" "$SELECTED_COLOR" "$_AGENTIC_SUGGESTION" "$RESET"
        printf '%s[Opt+Enter ↵ to select]%s\n' "$DARK_GRAY" "$RESET"
        
        # Move cursor back to original position 
        tput cuu "$((count + 1))"
        tput cr  # Carriage return
    fi
    
    # Restore cursor position
    tput rc
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