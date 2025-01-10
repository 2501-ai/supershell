#!/usr/bin/env zsh


# Clear the zsh-autosuggestions suggestions.
_clear_zsh_autosuggestions() {
    # Check if the zsh-autosuggestions plugin is loaded
    if [[ -n "${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE+x}" ]]; then
        # Clears the active suggestion
        _zsh_autosuggest_clear
        # Force redraw the prompt
        zle -R
    fi
}

# Disable zsh-autosuggestions
_disable_zsh_autosuggestions() {
    if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
        _OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=""
    fi
}

# Enable zsh-autosuggestions
_enable_zsh_autosuggestions() {
    if [[ -n "$_OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="$_OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"
        unset _OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
    fi
}

# Reset the state of the plugin
_reset_state() {
    info "[ZSH] Resetting state"
    # IN_SUGGESTION_MODE=false
    CURRENT_SUGGESTION_INDEX=0
    HISTORY_MODE=true
    _clear_suggestions

    # if [[ -z "$BUFFER" ]]; then
    #     local message="use ↓ when typing to invoke AI"
    #     POSTDISPLAY="$message"
    #     region_highlight+=("0 $#message fg=242")
    # fi
}

# handle the tab key
_handle_backspace() {
    zle .backward-delete-char

    if [[ -z "$BUFFER" ]]; then
        POSTDISPLAY=""
        _reset_state
         _clear_suggestions
        printf '\r\033[K' 
        zle reset-prompt 
    fi
}

# Handle word deletion
_handle_backward_kill_word() {
    zle .backward-kill-word

    if [[ -z "$BUFFER" ]]; then
        POSTDISPLAY=""
        _reset_state
    fi
}

# Handle the clear screen
_handle_clear_screen() {
    zle .clear-screen
    _reset_state
}

# Reset the state on redraw if the buffer is empty
#_handle_redraw() {
#  info "[ZSH] Redraw event"
#  [[ -z "$BUFFER" ]] && _reset_state
#}

# Detect buffer changes
_check_buffer_change() {
    info "[ZSH] Checking buffer change"
    # If the buffer has changed,
    if [[ "$BUFFER" != "$_LAST_BUFFER" ]]; then
        _LAST_BUFFER="$BUFFER"
    fi

}