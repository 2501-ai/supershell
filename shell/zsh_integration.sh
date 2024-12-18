#!/bin/bash
# Zsh-specific integration

# For zsh
if [ -z "$ZSH_VERSION" ]; then
    return 
fi

autoload -U add-zle-hook-widget
typeset -ga _FETCHED_SUGGESTIONS

# Handle CTRL+C
TRAPINT() {
    _cleanup_debounce
    return $(( 128 + $1 ))
}

# Handle Enter key
_zsh_accept_line() {
    _cleanup_debounce
    zle .accept-line
}
# Flag to control completion triggering
TRIGGER_COMPLETION=true

# Create and bind navigation widgets
_zsh_select_next() {
    declare -p | grep _FETCHED_SUGGESTIONS
    
    TRIGGER_COMPLETION=false
    _select_next_suggestion
    zle -R
}

_zsh_select_prev() {
    TRIGGER_COMPLETION=false
    _select_prev_suggestion
    zle -R
}

_zsh_completion() {
    if $TRIGGER_COMPLETION; then
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

# Bind keys using terminfo codes
[[ -n "${key[Up]}"   ]] && {
    bindkey "${key[Up]}"   _zsh_select_prev
}
[[ -n "${key[Down]}" ]] && {
    bindkey "${key[Down]}" _zsh_select_next
}

# Add the completion hook
add-zle-hook-widget line-pre-redraw _zsh_completion

info "registered zsh hooks"