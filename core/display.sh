#!/bin/bash

# Display handling
CURRENT_SUGGESTION_INDEX=0

_start_loading() {
    tput sc # Save cursor position

    clear_lines_force # Making sure we clear the precedent suggestions if any

    printf '\r'

    printf '\033[%s ⏳ Fetching suggestions...' "$GRAY_90"

    restore_cursor # Restore cursor position
}

_display_suggestions() {
    _read_suggestions  # Read suggestions from file
    info "Display Suggestions: ${_FETCHED_SUGGESTIONS[*]}"
    info "Suggestions length: ${#_FETCHED_SUGGESTIONS[@]}"
    info "Current suggestion index: $CURRENT_SUGGESTION_INDEX"
    info "Agentic suggestion: $_AGENTIC_SUGGESTION"

    tput sc # Save cursor position

    clear_lines

    # Print the current command line
    # printf '%s' "$READLINE_LINE"

#    zle -R _FETCHED_SUGGESTIONS
    if [[ ${#_FETCHED_SUGGESTIONS[@]} -gt 0 ]]; then
        # Move to next line and display suggestions (to test)
        printf '\033[%s┃\n' "$GRAY_90"

        # Display remaining suggestions with dots
        local count=0
        local IFS=$'\n'
        for sug in "${_FETCHED_SUGGESTIONS[@]}"; do
            if [ $count -eq "$MAX_SUGGESTIONS" ]; then
                break
            fi

            if [ $count -eq $CURRENT_SUGGESTION_INDEX ]; then
                # Display selected suggestion in green with arrow
                printf '\033[%s┣━ \033[38;5;%s⌲ %s\033[38;5;%s Enter ↵ to select\n' "$GRAY_90" "$GREEN" "$sug" "$GRAY_240"
            else
                # Display other suggestions in shades of gray defined in colors.sh
                printf '\033[%s┣━ \033[38;5;%sm%s\033[0m\n' "$GRAY_90" "${SUGGESTION_COLORS[$count]}" "$sug"
            fi
            count=$((count + 1))
        done

        info "suggestions: ${_FETCHED_SUGGESTIONS[*]}"

        # Display the agent suggestion
        printf '\033[%s┃\n' "$GRAY_90"
        printf '\033[%s┣━━ Launch an AI agent with 2501 using Opt + Enter\n' "$GRAY_90"
        printf '\033[%s┗━\033[38;5;%s ✨ @2501 %s\n' "$GRAY_90" "$GREEN_ALT" "$_AGENTIC_SUGGESTION"

        # Display the navigation hint
        printf '\n'
        printf '\033[%s ↑↓ \033[%sNavigate \033[%s↵ \033[%sSelect \033[%sOpt + ↵ \033[%sRun Agent ' "$WHITE_0" "$GRAY_90" "$WHITE_0" "$GRAY_90" "$WHITE_0" "$GRAY_90"

        # Move cursor back to original position
        tput cuu "$((count + 1))" # TODO: test with bash
        tput cr
        # printf '\033[%dC' "${#READLINE_LINE}" (useless/noside effect with zsh)

    fi

    restore_cursor # Restore cursor position
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