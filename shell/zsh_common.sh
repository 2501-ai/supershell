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
    CURRENT_SUGGESTION_INDEX=-1
    HISTORY_MODE=true
    _clear_suggestions
}

# handle the tab key
_handle_backspace() {
    zle .backward-delete-char

    if [[ -z "$BUFFER" ]]; then
        # POSTDISPLAY=""
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
        # POSTDISPLAY=""
        _reset_state
    fi
}

# Handle the clear screen
_handle_clear_screen() {
    zle .clear-screen
    _reset_state
}
