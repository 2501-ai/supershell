#!/bin/bash
# ========================================================================================
# Zsh integration
# ========================================================================================

# Key Bindings:
#   Up/Down    - Navigate through suggestions
#   Tab        - Accept current line
#   Enter      - Execute selected suggestion
#   Ctrl+C     - Cancel current operation

# ========================================================================================
# State Management
# ========================================================================================
CURRENT_SUGGESTION=""
IN_SUGGESTION_MODE=false
IN_HISTORY_MODE=false
TRIGGER_COMPLETION=false

# ========================================================================================
# ZSH Autosuggestions Management
# ========================================================================================
_disable_zsh_autosuggestions() {
    if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
        _OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=""
    fi
}

_enable_zsh_autosuggestions() {
    if [[ -n "$_OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="$_OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"
        unset _OLD_ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
    fi
}

_clear_zsh_autosuggestions() {
    if [[ -n "${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE+x}" ]]; then
        _zsh_autosuggest_clear
        zle -R
    fi
}

# ========================================================================================
# Navigation Functions
# ========================================================================================
_zsh_select_next() {
    info "[ZSH] _zsh_select_next called"
    info "[ZSH] Current state: IN_SUGGESTION_MODE=$IN_SUGGESTION_MODE, CURRENT_SUGGESTION_INDEX=$CURRENT_SUGGESTION_INDEX"
    
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        _handle_suggestion_navigation "next"
        return
    fi

    _handle_history_navigation "next"
}

_zsh_select_prev() {
    info "[ZSH] _zsh_select_prev called"
    info "[ZSH] Current state: IN_SUGGESTION_MODE=$IN_SUGGESTION_MODE, CURRENT_SUGGESTION_INDEX=$CURRENT_SUGGESTION_INDEX"
    
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        _handle_suggestion_navigation "prev"
        return
    fi

    info "[ZSH] Normal history navigation"
    zle .up-line-or-history
}

# ========================================================================================
# Suggestion Navigation Helpers
# ========================================================================================
_handle_suggestion_navigation() {
    local direction="$1"
    info "[ZSH] Currently in suggestion mode"
    _read_suggestions
    local suggestions_count=${#_FETCHED_SUGGESTIONS[@]}
    
    if (( suggestions_count > 0 )); then
        if [[ "$direction" == "next" ]]; then
            _navigate_next_suggestion "$suggestions_count"
        else
            _navigate_prev_suggestion "$suggestions_count"
        fi
    fi
}

_navigate_next_suggestion() {
    local suggestions_count=$1
    if (( suggestions_count <= 0 )); then
        return
    fi
    if (( CURRENT_SUGGESTION_INDEX < 0 )); then
        CURRENT_SUGGESTION_INDEX=0
    else
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % suggestions_count ))
    fi
    _update_suggestion "$@"
}

_navigate_prev_suggestion() {
    local suggestions_count=$1
    if (( suggestions_count <= 0 )); then
        return
    fi
    if (( CURRENT_SUGGESTION_INDEX < 0 )); then
        CURRENT_SUGGESTION_INDEX=$(( suggestions_count - 1 ))
    else
        CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + suggestions_count) % suggestions_count ))
    fi
    _update_suggestion "$@"
}

_update_suggestion() {
    CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
    if [[ -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
        _disable_zsh_autosuggestions
        _display_suggestions
        zle -R
    fi
}

# ========================================================================================
# History Navigation Helper
# ========================================================================================
_handle_history_navigation() {
    info "[ZSH] Trying history navigation"
    local current_buffer="$BUFFER"
    local old_buffer="$BUFFER"
    
    zle .down-line-or-history
    local new_buffer="$BUFFER"
    
    if [[ "$old_buffer" == "$new_buffer" ]]; then
        _switch_to_suggestion_mode "$current_buffer"
    else
        info "[ZSH] Successfully navigated history"
        IN_SUGGESTION_MODE=false
        _clear_suggestions
    fi
}

_switch_to_suggestion_mode() {
    local current_buffer="$1"
    info "[ZSH] Reached end of history, switching to suggestions"
    _reset_state
    BUFFER="$current_buffer"
    IN_SUGGESTION_MODE=true
    _universal_complete "$current_buffer"
    CURRENT_SUGGESTION_INDEX=-1
    _display_suggestions
    zle -R
}

# ========================================================================================
# Action Functions
# ========================================================================================
_zsh_accept_line() {
    _clear_zsh_autosuggestions
    
    if [[ "$IN_SUGGESTION_MODE" == "true" && -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
        IN_SUGGESTION_MODE=false
        _clear_suggestions
        zle .accept-line
        return
    fi
    
    zle .complete-word
}

_zsh_execute_line() {
    if [[ "$IN_SUGGESTION_MODE" == "true" && -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
    fi
    
    _reset_state
    zle .accept-line
}

# ========================================================================================
# State Management Functions
# ========================================================================================
_reset_state() {
    info "[ZSH] Resetting state"
    IN_SUGGESTION_MODE=false
    CURRENT_SUGGESTION_INDEX=-1
    CURRENT_SUGGESTION=""
    _enable_zsh_autosuggestions
    _clear_suggestions
}

_clear_suggestions() {
    if [[ -n "$_LAST_DISPLAYED_SUGGESTIONS" ]]; then
        local num_lines
        num_lines=$(echo -n "$_LAST_DISPLAYED_SUGGESTIONS" | wc -l)
        for ((i=0; i<num_lines; i++)); do
            tput cuu1
            tput el
        done
        _LAST_DISPLAYED_SUGGESTIONS=""
    fi
}

# ========================================================================================
# Buffer Management
# ========================================================================================
_check_buffer_change() {
    if [[ -z "$LAST_BUFFER" ]]; then
        LAST_BUFFER="$BUFFER"
        return
    fi

    if (( ${#BUFFER} < ${#LAST_BUFFER} )); then
        _reset_state
    fi

    LAST_BUFFER="$BUFFER"
}

_zsh_completion() {
    info "[ZSH] Completion hook called with BUFFER: '$BUFFER'"
    
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        info "[ZSH] In suggestion mode, skipping reset"
        _disable_zsh_autosuggestions
        return
    fi
    
    if [[ -z "$BUFFER" && "$IN_SUGGESTION_MODE" == "false" ]]; then
        info "[ZSH] Empty buffer and not in suggestion mode, resetting state"
        _reset_state
    fi
}

# ========================================================================================
# Setup and Initialization
# ========================================================================================
autoload -U add-zle-hook-widget

# Register widgets
zle -N _zsh_select_next
zle -N _zsh_select_prev
zle -N _zsh_accept_line
zle -N _zsh_execute_line

# Bind keys
bindkey "^M" _zsh_execute_line    # Enter
bindkey "^I" _zsh_accept_line     # Tab
bindkey "^[[A" _zsh_select_prev   # Up arrow
bindkey "^[[B" _zsh_select_next   # Down arrow

# Register hooks
add-zle-hook-widget line-init _check_buffer_change
add-zle-hook-widget line-finish _check_buffer_change
add-zle-hook-widget line-pre-redraw _zsh_completion
add-zle-hook-widget keymap-select _check_buffer_change
