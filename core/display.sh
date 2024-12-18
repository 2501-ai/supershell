#!/usr/bin/env bash
# Display handling

echo "[DISPLAY] Initializing display module..."
CURRENT_SUGGESTION_INDEX=1
SUGGESTIONS=()

_show_loading() {
    echo "[DISPLAY] Showing loading indicator"
    clear_lines
    printf '%s' "$READLINE_LINE"
    printf '\n%s⋯ fetching suggestions...%s' "$GRAY" "$RESET"
    printf '\033[1A\r'
    printf '\033[%dC' "${#READLINE_LINE}"
}

# testsug=("test1" "test2" "test3")
# for (( i=0; i<${#testsug[@]}; i++ )); do
#     echo "suggestion $i: ${testsug[$i]}"
# done

_display_suggestions() {
    local suggestions=("$@")
    
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
        
        printf '\033[38;5;240m[TAB to execute highlighted suggestion]\033[0m\n'
    fi
    
    # Restore cursor position
    printf '\033[u'
}

# Add these navigation functions
_select_next_suggestion() {
    echo "[DISPLAY] Selecting next suggestion"
    if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % ${#SUGGESTIONS[@]} ))
        echo "[DISPLAY] New index: $CURRENT_SUGGESTION_INDEX"
        _display_suggestions "${SUGGESTIONS[@]}"
    fi
}

_select_prev_suggestion() {
    echo "[DISPLAY] Selecting previous suggestion"
    if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + ${#SUGGESTIONS[@]}) % ${#SUGGESTIONS[@]} ))
        echo "[DISPLAY] New index: $CURRENT_SUGGESTION_INDEX"
        _display_suggestions "${SUGGESTIONS[@]}"
    fi
}