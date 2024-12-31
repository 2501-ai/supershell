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

# Flag to control completion triggering
TRIGGER_COMPLETION=true

# Should bind keys
BIND_KEYS=true

# Handle CTRL+C
TRAPINT() {
    _cleanup_debounce
    return "$1"
}

# Handle Tab key
_zsh_accept_line() {
    TRIGGER_COMPLETION=false
    _cleanup_debounce
    _clear_suggestions
    _display_suggestions # Clears the display
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
    _clear_suggestions
    # _display_suggestions # Clears the display
    info "Current Suggestion: $CURRENT_SUGGESTION"
    # set the current prompt to the selected suggestion
    if [[ -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
        CURRENT_SUGGESTION=""
    fi

    if [[ "$BIND_KEYS" == "false" ]]; then
        _unbind_selection_keys
        BIND_KEYS=true
    fi

    zle .accept-line
}

# Create and bind navigation widgets
_zsh_select_next() {
    TRIGGER_COMPLETION=false
    _select_next_suggestion
    CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX + 1]}"
    info "Selected next Suggestion: $CURRENT_SUGGESTION"
    zle -R
}

_zsh_select_prev() {
    TRIGGER_COMPLETION=false
    _select_prev_suggestion
    CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX + 1]}"
    info "Selected prev Suggestion: $CURRENT_SUGGESTION"
    zle -R
}

_zsh_completion() {
    if [[ -z "$BUFFER" ]]; then
        TRIGGER_COMPLETION=false
        if [[ "$BIND_KEYS" == "false" ]]; then
            _unbind_selection_keys
            BIND_KEYS=true
        fi
        return
    fi

    if $TRIGGER_COMPLETION; then
        CURRENT_SUGGESTION=""
        CURRENT_SUGGESTION_INDEX=0
        _clear_suggestions
        _universal_complete "$BUFFER" "$CURSOR"
        zle -R

        if [[ "$BIND_KEYS" == "true" ]]; then
            _bind_selection_keys
            BIND_KEYS=false
        fi
    else
        TRIGGER_COMPLETION=true
    fi
}

# Register the widgets
zle -N _zsh_select_next
zle -N _zsh_select_prev
zle -N _zsh_accept_line
zle -N _zsh_execute_line

# Store the original key bindings
_up_key_binding=''
_down_key_binding=''

_bind_selection_keys() {
    info "Binding selection keys"
    _up_key_binding=$(bindkey "${key[Up]}" | awk '{$1=""; print substr($0,2)}')
    _down_key_binding=$(bindkey "${key[Down]}" | awk '{$1=""; print substr($0,2)}')
    [[ -n "${key[Up]}" ]] && {
        bindkey -r "${key[Up]}" # Reset the key binding
        bindkey "${key[Up]}" _zsh_select_prev
    }
    [[ -n "${key[Down]}" ]] && {
        bindkey -r "${key[Down]}" # Reset the key binding
        bindkey "${key[Down]}" _zsh_select_next
    }
}

# Unbind keys using terminfo codes and restore default behavior
_unbind_selection_keys() {
    info "Unbinding selection keys"
    [[ -n "${key[Up]}" ]] && {
        bindkey -r "${key[Up]}" # Reset the key binding
        bindkey "${key[Up]}" "${_up_key_binding}"
    }
    [[ -n "${key[Down]}" ]] && {
        bindkey -r "${key[Down]}" # Reset the key binding
        bindkey "${key[Down]}" "${_down_key_binding}"
    }
}

bindkey "^M" _zsh_execute_line # Bind Enter key to _zsh_execute_line
bindkey "^I" _zsh_accept_line  # Bind Tab key to _zsh_accept_line

# Add the completion hook
add-zle-hook-widget line-pre-redraw _zsh_completion

info "registered zsh hooks"
