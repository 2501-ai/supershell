#!/bin/bash
# Display handling

_show_loading() {
    local -a spinner=('𓃉𓃉𓃉' '𓃉𓃉∘' '𓃉∘°' '∘°∘' '°∘𓃉' '∘𓃉𓃉')
    local i=0

    GRAY=$'\033[90m'
    RESET=$'\033[0m'
    
    # Save initial cursor position
    printf '\033[s'

    clear_lines

    while [ "$IS_LOADING" = "true" ]; do
        # Return to saved position
        printf '\033[u'
        
        # Move down one line
        printf '\n'
        
        # Print spinner and message
        printf '%s%-3s fetching suggestions...%s' "$GRAY" "${spinner[i]}" "$RESET"

        # Return to original cursor position
        printf '\033[u'
        
        sleep 0.1
        i=$((i % ${#spinner[@]}))
        ((i++))
    done
    
    # Clean up after loading is done
    printf '\033[u\n\033[K'
    printf '\033[u'
}

# utils unicode →  •

_display_suggestions() {
    local response="$1"
    local max_suggestions=4
    
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
            
            # Suggestion header
            printf '\033[90m┏━━━ Suggestions ━━━━━━━━━━━ TAB to execute highlighted suggestion\033[0m\n'

            # First suggestion with 1 character
            printf '\033[90m┣╸➜ %s\033[0m\n' "$CURRENT_SUGGESTION"
            
            # Display remaining suggestions with dots
            local count=1
            while IFS= read -r suggestion; do
                if [ $count -lt $max_suggestions ]; then
                    printf '\033[90m┣╸ %s\033[0m\n' "$suggestion"
                    ((count++))
                else
                    break
                fi
            done < <(echo "$response" | jq -r '.commands[1:][]' 2>/dev/null)

            local prompts=$(echo "$response" | jq -r '.prompts[0]' 2>/dev/null || echo "")
            
            # Print execution hint
            printf '\033[90m┣━━━ Agent Mode ━━━━━━━━━━━━ Opt+TAB\n'
            printf '\033[38;5;240m┗ %s (launch as an agent)]\033[0m' "$prompts"
            
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