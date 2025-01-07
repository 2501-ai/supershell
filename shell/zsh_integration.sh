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
TRIGGER_COMPLETION=false

# Control whether completion should be triggered
IN_SUGGESTION_MODE=false

source "$SCRIPT_DIR/shell/zsh_common.sh"

# Handle CTRL+C
TRAPINT() {
    _cleanup_debounce
    return "$1"
}

# Handle Enter key
_zsh_execute_line() {
    TRIGGER_COMPLETION=false
    _cleanup_debounce
    _clear_suggestions
    # Execute the current line
    zle .accept-line
}

# Detect buffer change and toggle suggestions mode if the end of history is reached
_toggle_suggestions_mode() {
    # Navigation dans l'historique
    info "[ZSH] Trying history navigation"
    local current_buffer="$1"

    # Sauvegarder le buffer actuel
    local new_buffer="$BUFFER"

    # If the buffer is unchanged, switch to suggestions mode
    if [[ "$current_buffer" == "$new_buffer" ]]; then
        info "[ZSH] Switching to suggestions"
        IN_SUGGESTION_MODE=true
        _disable_zsh_autosuggestions
    else
        info "[ZSH] Disabling suggestions"
        IN_SUGGESTION_MODE=false
        _enable_zsh_autosuggestions
    fi
}

_zsh_completion() {
  if [[ -n "$TRIGGER_COMPLETION" ]] && [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
      CURRENT_SUGGESTION=""
      _universal_complete "$BUFFER"
    else
        TRIGGER_COMPLETION=true
    fi
}

_zsh_on_downkey_pressed() {
    info "[ZSH EVENT] Down key pressed"
    TRIGGER_COMPLETION=false
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
      _select_next_suggestion
      CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX+1]}"
      if [[ -n "$CURRENT_SUGGESTION" ]]; then
        info "[ZSH] Selected next Suggestion: $CURRENT_SUGGESTION"
        # Synchronise the buffer with the selected suggestion
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
        zle -R
      fi
    else
      local current_buffer="$BUFFER"
      zle "$_down_key_binding"
      _toggle_suggestions_mode $current_buffer
      # If we switched to suggestions mode, trigger completion
      if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        CURRENT_SUGGESTION_INDEX=0
        zle -R
        [[ -n "$BUFFER" ]] && _zsh_completion
      fi
    fi
}

_zsh_on_upkey_pressed() {
    info "[ZSH EVENT] Up key pressed"
    TRIGGER_COMPLETION=false
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
      _select_prev_suggestion
      CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX+1]}"
      if [[ -n "$CURRENT_SUGGESTION" ]]; then
        info "[ZSH] Selected prev Suggestion: $CURRENT_SUGGESTION"
        # Synchronise the buffer with the selected suggestion
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
        zle -R
      fi
    else
      zle "$_up_key_binding"
    fi

}

_zsh_execute_with_2501() {
    info "[ZSH] Execute with 2501 triggered"
    # Sauvegarde le buffer actuel
    BUFFER="@2501 $_AGENTIC_SUGGESTION"
    tput sc # Save cursor position
    clear_lines
    tput rc # Restore cursor position
    zle .accept-line
#    zle reset-prompt

}

# ========================================================================================
# Register the widgets
# ========================================================================================

# Set or overwrite the widgets
zle -N backward-delete-char _handle_backspace
zle -N backward-kill-word _handle_backward_kill_word
zle -N clear-screen _handle_clear_screen

# Register the user widgets to make them available with ZLE.
zle -N _zsh_on_downkey_pressed # Register the next suggestion widget
zle -N _zsh_on_upkey_pressed # Register the previous suggestion widget
#zle -N _zsh_accept_line # Register the line acceptance widget
zle -N _zsh_execute_line # Register the line execution widget

# Store the original key binding events.
_up_key_binding=$(bindkey "${key[Up]}" | awk '{$1=""; print substr($0,2)}')
_down_key_binding=$(bindkey "${key[Down]}" | awk '{$1=""; print substr($0,2)}')

bindkey "^M" _zsh_execute_line  # Bind Enter key to _zsh_execute_line
#bindkey "^I" _zsh_accept_line # Bind Tab key to _zsh_accept_line
[[ -n "${key[Up]}"   ]] && bindkey "${key[Up]}"   _zsh_on_upkey_pressed
[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" _zsh_on_downkey_pressed

# Keep track of the last buffer
LAST_BUFFER=""

# Add hooks to add functionality to existing widgets.

add-zle-hook-widget line-init _handle_redraw
add-zle-hook-widget line-finish _handle_redraw
add-zle-hook-widget line-pre-redraw _handle_redraw
add-zle-hook-widget keymap-select _handle_redraw

add-zle-hook-widget line-init _check_buffer_change
add-zle-hook-widget line-finish _check_buffer_change
add-zle-hook-widget keymap-select _check_buffer_change

# Add the completion hook
add-zle-hook-widget line-pre-redraw _zsh_completion


# Ajouter le nouveau widget avec plus de logs
zle -N _zsh_execute_with_2501

bindkey "^J" _zsh_execute_with_2501        # Control+J

