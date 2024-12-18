#!/bin/bash
# Display handling
CURRENT_SUGGESTION_INDEX=1
SUGGESTIONS=()

_show_loading() {
    clear_lines
    printf '%s' "$READLINE_LINE"
    printf '\n%s⋯ fetching suggestions...%s' "$GRAY" "$RESET"
    printf '\033[1A\r'
    printf '\033[%dC' "${#READLINE_LINE}"
}

_display_suggestions() {
    local max_suggestions=4  # Maximum number of suggestions to display
    SUGGESTIONS=$@
    info "Display Suggestions: $SUGGESTIONS"
    info "Current suggestion index: $CURRENT_SUGGESTION_INDEX"
    
    # Save cursor position
    printf '\033[s'
    
    clear_lines
    
    # Print the current command line
    printf '%s' "$READLINE_LINE"
    
    if [[ -n "$SUGGESTIONS" ]]; then
    # Get the selected suggestion
        local _suggestion=""
        local _suggestions=()
        local IFS=$'\n'
        for i in ${!SUGGESTIONS[*]}; do
            info "suggestion: $i"
            if [ $i -eq $CURRENT_SUGGESTION_INDEX ]; then
                _suggestion=$i
            else
                $_suggestions+=("$i")
            fi
        done
        info "selected _suggestion: $_suggestion"
        # Move to next line and display suggestions
        printf '\n'
        printf '\033[90m-------SUGGEST MODE--------------\033[0m\n'
        
        # Display first _suggestion with arrow
        printf '\033[90m→ %s\033[0m\n' "$_suggestion"
        
        # Display remaining suggestions with dots
        local count=1
        for sug in "$_suggestions"; do
            if [ $count -eq $max_suggestions ]; then
                printf '\033[90m→ %s\033[0m\n' "$sug"
                break
            fi
            printf '\033[90m. %s\033[0m\n' "$sug"
            count=$((count + 1))
        done
        
        # local prompts=$(echo "$SUGGESTIONS" | jq -r '.prompts[0]' 2>/dev/null || echo "")
        
        # Print execution hint
        printf '\033[38;5;240m[TAB to execute highlighted _suggestion]\033[0m\n'
        # printf '\033[90m-------AGENT MODE----------------\033[0m\n'
        # printf '\033[38;5;240m[Opt+TAB @2501 %s (launch as an agent)]\033[0m' "$prompts"
        
        # Move cursor back to original position
        printf '\033[%dA\r' "$((count + 1))"
        printf '\033[%dC' "${#READLINE_LINE}"
    fi
    
    # Restore cursor position
    printf '\033[u'
}

# Add these navigation functions
_select_next_suggestion() {
    info "select next"
    info "suggestions: ${#SUGGESTIONS[@]}"
    # Test if there are suggestions
    if [ ${#SUGGESTIONS[@]} -gt 0 ] && [ $CURRENT_SUGGESTION_INDEX -lt $((${#SUGGESTIONS[@]} - 1)) ]; then
        CURRENT_SUGGESTION_INDEX=$((CURRENT_SUGGESTION_INDEX + 1))
        _display_suggestions "$LAST_RESPONSE"
    fi
}

_select_prev_suggestion() {
    info "select prev"
    if [ $CURRENT_SUGGESTION_INDEX -gt 0 ] && [ ${#SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$((CURRENT_SUGGESTION_INDEX - 1))
        _display_suggestions "$LAST_RESPONSE"
    fi
}