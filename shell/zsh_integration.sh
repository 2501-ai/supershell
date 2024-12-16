#!/bin/bash
# Zsh-specific integration

# For zsh
if [ -n "$ZSH_VERSION" ]; then
    autoload -U add-zle-hook-widget
      
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

    _zsh_completion() {
        _universal_complete "$BUFFER" "$CURSOR"
        zle -R
    }
    _zsh_execute() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            _execute_suggestion
            zle reset-prompt # This line resets the prompt after executing the command
        fi
    }
    zle -N _zsh_completion
    zle -N _zsh_execute
    zle -N accept-line _zsh_accept_line
    add-zle-hook-widget line-pre-redraw _zsh_completion
    _zsh_select_next() { _select_next_suggestion; zle -R }
    _zsh_select_prev() { _select_prev_suggestion; zle -R }
    zle -N _zsh_select_next
    zle -N _zsh_select_prev
    bindkey '^[[A' _zsh_select_prev  # Up arrow
    bindkey '^[[B' _zsh_select_next  # Down arrow
    bindkey '^I' _zsh_execute
fi