#!/bin/bash
# Display handling

_show_loading() {
    clear_lines
    printf '%s' "$READLINE_LINE"
    printf '\n%s⋯ fetching suggestions...%s' "$GRAY" "$RESET"
    printf '\033[1A\r'
    printf '\033[%dC' "${#READLINE_LINE}"
}

_display_suggestions() {
    local response="$1"
    local max_suggestions=4  # Maximum number of suggestions to display
    
    # Save cursor position
    printf '\033[s'
    
    clear_lines
    
    # Print the current command line
    printf '%s' "$READLINE_LINE"
    
    if echo "$response" | jq empty 2>/dev/null; then
        CURRENT_SUGGESTION=$(echo "$response" | jq -r '.commands[0]' 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_SUGGESTION" ] && [ "$CURRENT_SUGGESTION" != "null" ]; then
            # Move to next line and display suggestions
            printf '\n'
            
            # Display first suggestion with arrow
            printf '\033[90m-------SUGGEST MODE--------------\033[0m\n'
            printf '\033[90m→ %s\033[0m\n' "$CURRENT_SUGGESTION"
            
            # Display remaining suggestions with dots
            local count=1
            while IFS= read -r suggestion; do
                if [ $count -lt $max_suggestions ]; then
                    printf '\033[90m• %s\033[0m\n' "$suggestion"
                    ((count++))
                else
                    break
                fi
            done < <(echo "$response" | jq -r '.commands[1:][]' 2>/dev/null)

            local prompts=$(echo "$response" | jq -r '.prompts[0]' 2>/dev/null || echo "")
            
            # Print execution hint
            printf '\033[38;5;240m[TAB to execute highlighted suggestion]\033[0m\n'
            printf '\033[90m-------AGENT MODE----------------\033[0m\n'
            printf '\033[38;5;240m[Opt+TAB @2501 %s (launch as an agent)]\033[0m' "$prompts"
            
            # Move cursor back to original position
            printf '\033[%dA\r' "$((count + 1))"
            printf '\033[%dC' "${#READLINE_LINE}"
        fi
    fi
    
    # Restore cursor position
    printf '\033[u'
}

# Add these navigation functions
_select_next_suggestion() {
    if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % ${#SUGGESTIONS[@]} ))
        CURRENT_SUGGESTION="${SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
        _display_suggestions "$LAST_RESPONSE"
    fi
}

_select_prev_suggestion() {
    if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + ${#SUGGESTIONS[@]}) % ${#SUGGESTIONS[@]} ))
        CURRENT_SUGGESTION="${SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
        _display_suggestions "$LAST_RESPONSE"
    fi
}