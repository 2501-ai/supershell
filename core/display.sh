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

    GRAY=$'\033[90m'
    RESET=$'\033[0m'

    printf '\033[s'

    clear_lines

    printf '\033[u'

    # Move down one line
    printf '\033[1B'
    printf '\r'

    # Print spinner and message
    printf "\033[90m𓃉𓃉𓃉"
    # printf '%s%-3s fetching suggestions...%s' "$GRAY" "${spinner[i]}" "$RESET"

    printf '\033[u'

    i=$(( (i + 1) % ${#spinner[@]} ))
    # i=$((i % ${#spinner[@]}))
    # ((i++))

    # Clean up after loading is done
    printf '\033[u'
}

_display_suggestions() {
    _read_suggestions  # Read suggestions from file
    info "Display Suggestions: ${_FETCHED_SUGGESTIONS[*]}"
    info "Suggestions length: ${#_FETCHED_SUGGESTIONS[@]}"
    info "Current suggestion index: $CURRENT_SUGGESTION_INDEX"
    info "Agentic suggestion: $_AGENTIC_SUGGESTION"

    # Save cursor position
    printf '\033[s'

    clear_lines

    # Print the current command line
    # printf '%s' "$READLINE_LINE"

#    zle -R _FETCHED_SUGGESTIONS
    if [[ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]]; then
        # Move to next line and display suggestions (to test)
        # printf '\n'
        printf '\033[90m┣━━━ 2501 autocomplete ━━━━━━━━━━━\033[0m\n'

        # Display remaining suggestions with dots
        local count=0
        local IFS=$'\n'
        for sug in "${_FETCHED_SUGGESTIONS[@]}"; do
            if [ $count -eq "$MAX_SUGGESTIONS" ]; then
                break
            fi

            if [ $count -eq $CURRENT_SUGGESTION_INDEX ]; then
                printf '\033[90m┣╸\033[38;5;%s➜ %s\033[0m\n' "$SELECTED_COLOR" "$sug"
            else
                printf '\033[90m┣╸ %s\033[0m\n' "$sug"
            fi
            count=$((count + 1))
        done

        info "suggestions: ${_FETCHED_SUGGESTIONS[*]}"

        # Print execution hint
        printf '\033[38;5;240m[↑↓ to navigate, Enter ↵ to select]\033[0m\n'
        printf '\033[90m \033[0m\n'
        printf '\033[90m┣━━━ 2501 agent ━━━━━━━━━━━━━━━━━\033[0m\n'
        printf '\033[90m┗━ \033[38;5;%s@2501 %s\033[0m\n' "$SELECTED_COLOR" "$_AGENTIC_SUGGESTION"
        printf '\033[38;5;240m[Opt+Enter ↵ to select]\033[0m\n'

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
#    info "select next"
    # Test if there are suggestions
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % ${#_FETCHED_SUGGESTIONS[@]} ))
#        info "[select next] current suggestion index: $CURRENT_SUGGESTION_INDEX"
        _display_suggestions
    else
        info "[select next] No suggestions to navigate"
    fi
}

_select_prev_suggestion() {
    _read_suggestions  # Read suggestions from file
#    info "[select prev] select prev"
    if [ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]; then
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + ${#_FETCHED_SUGGESTIONS[@]}) % ${#_FETCHED_SUGGESTIONS[@]} ))
        _display_suggestions
    else
        info "[select prev] No suggestions to navigate"
    fi
}