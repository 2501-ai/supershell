#!/usr/bin/env bash
# Display handling

CURRENT_SUGGESTION_INDEX=0
SUGGESTIONS=()
CURRENT_SUGGESTION=""

_show_loading() {
    clear_lines
    printf '%s' "$READLINE_LINE"
    printf '\n%s⋯ fetching suggestions...%s' "$GRAY" "$RESET"
    printf '\033[1A\r'
    printf '\033[%dC' "${#READLINE_LINE}"
}

_display_suggestions() {
    local suggestions=("$@")
    SUGGESTIONS=("${suggestions[@]}")
    
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        CURRENT_SUGGESTION="${suggestions[$CURRENT_SUGGESTION_INDEX]}"
    else
        CURRENT_SUGGESTION=""
    fi
    
    # Save cursor position
    printf '\033[s'
    
    clear_lines
    
    # Print the current command line
    printf '%s' "$READLINE_LINE"
    
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        printf '\n'
        printf '\033[90m-------SUGGEST MODE--------------\033[0m\n'
        
        local count=0
        local max_suggestions=4
        
        for suggestion in "${suggestions[@]}"; do
            if [ $count -lt $max_suggestions ]; then
                if [ $count -eq $CURRENT_SUGGESTION_INDEX ]; then
                    printf '\033[1;32m→ %s\033[0m\n' "$suggestion"
                else
                    printf '\033[90m• %s\033[0m\n' "$suggestion"
                fi
                ((count++))
            fi
        done
        
        printf '\033[38;5;240m[↑↓ to navigate, TAB to select]\033[0m\n'
    fi
    
    # Restore cursor position
    printf '\033[u'
}

_select_next_suggestion() {
    if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % ${#SUGGESTIONS[@]} ))
        CURRENT_SUGGESTION="${SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
        _display_suggestions "${SUGGESTIONS[@]}"
    fi
}

_select_prev_suggestion() {
    if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + ${#SUGGESTIONS[@]}) % ${#SUGGESTIONS[@]} ))
        CURRENT_SUGGESTION="${SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
        _display_suggestions "${SUGGESTIONS[@]}"
    fi
}