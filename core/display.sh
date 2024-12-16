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
    
    clear_lines
    
    if echo "$response" | jq empty 2>/dev/null; then
        CURRENT_SUGGESTION=$(echo "$response" | jq -r '.commands[0]' 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_SUGGESTION" ] && [ "$CURRENT_SUGGESTION" != "null" ]; then
            printf '%s' "$READLINE_LINE"
            printf '\n%s→ %s%s' "$GRAY" "$CURRENT_SUGGESTION" "$RESET"
            printf '\n%s[TAB to execute]%s' "$DARK_GRAY" "$RESET"
            printf '\033[2A\r'
            printf '\033[%dC' "${#READLINE_LINE}"
        fi
    else
        printf '%s' "$READLINE_LINE"
        printf '\n%sError fetching suggestions%s' "$RED" "$RESET"
        printf '\033[1A\r'
        printf '\033[%dC' "${#READLINE_LINE}"
    fi
}