#!/bin/bash
# ========================================================================================
# Zsh integration
# ========================================================================================

# Load the common shell functionality

# Key Bindings:
#   Up/Down    - Navigate through suggestions
#   Tab        - Accept current line
#   Enter      - Execute selected suggestion
#   Ctrl+C     - Cancel current operation

autoload -U add-zle-hook-widget
CURRENT_SUGGESTION=""

# Handle CTRL+C
TRAPINT() {
    _cleanup_debounce
    return $(( 128 + $1 ))
}

# Handle Tab key
_zsh_accept_line() {
    TRIGGER_COMPLETION=false
    _cleanup_debounce
    info "Current Suggestion: $CURRENT_SUGGESTION"
    # set the current prompt to the selected suggestion
    if [[ -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
    fi
}


# Handle Enter key
_zsh_execute_line() {
    TRIGGER_COMPLETION=false
    _cleanup_debounce
    info "Current Suggestion: $CURRENT_SUGGESTION"
    # set the current prompt to the selected suggestion
    if [[ -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
    fi
    zle .accept-line
}
# Flag to control completion triggering
TRIGGER_COMPLETION=true

# Create and bind navigation widgets
_zsh_select_next() {
    TRIGGER_COMPLETION=false
    _select_next_suggestion
    CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX+1]}"
    info "Selected next Suggestion: $CURRENT_SUGGESTION"
    zle -R
}

_zsh_select_prev() {
    TRIGGER_COMPLETION=false
    _select_prev_suggestion
    CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX+1]}"
    info "Selected prev Suggestion: $CURRENT_SUGGESTION"
    zle -R
}

_zsh_completion() {
    if $TRIGGER_COMPLETION; then
        CURRENT_SUGGESTION=""
        CURRENT_SUGGESTION_INDEX=0
        _universal_complete "$BUFFER" "$CURSOR"
        zle -R
    else
        TRIGGER_COMPLETION=true
    fi
}

# Register the widgets
zle -N _zsh_self_insert
zle -N _zsh_select_next
zle -N _zsh_select_prev
zle -N _zsh_accept_line
zle -N _zsh_execute_line

# Bind keys using terminfo codes
[[ -n "${key[Up]}"   ]] && bindkey "${key[Up]}"   _zsh_select_prev
[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" _zsh_select_next
bindkey "^M" _zsh_execute_line  # Bind Enter key to _zsh_execute_line
bindkey "^I" _zsh_accept_line # Bind Tab key to _zsh_accept_line

# Add the completion hook
add-zle-hook-widget line-pre-redraw _zsh_completion

info "registered zsh hooks"