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

# Control whether completion should be triggered
IN_SUGGESTION_MODE=false

# Control wherether an arrow key was pressed
ARROW_KEY_PRESSED=false

source "$SCRIPT_DIR/shell/zsh_common.sh"

# Handle CTRL+C
TRAPINT() {
    _zsh_on_sigint
    return "$1"
}

_zsh_on_sigint() {
    info "[ZSH EVENT] SIGINT"
    _cleanup_debounce
    # Clear the placeholder
    zle .clear-screen
    zle -R ''
    zle .redisplay
    zle .reset-prompt
}

# Handle Enter key
_zsh_execute_line() {
    _cleanup_debounce
    _clear_suggestions

    POSTDISPLAY=''
    # Execute the current line
    zle .accept-line
}

_zsh_handle_paste() {
    info "[ZSH] Paste event triggered"
    # Execute the default paste behavior
    zle .bracketed-paste
    # Clear any existing suggestions since we're pasting new content
    _cleanup_debounce
    _clear_suggestions
    # Reset the buffer state
    POSTDISPLAY=""
    # Trigger buffer modified to handle the new content
    _zsh_on_buffer_modified
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
  if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
    CURRENT_SUGGESTION=""
    _universal_complete "$BUFFER"
  fi
}

_zsh_on_downkey_pressed() {
  ARROW_KEY_PRESSED=true
  POSTDISPLAY=""
    info "[ZSH EVENT] Down key pressed"
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
      _toggle_suggestions_mode "$current_buffer"
      # If we switched to suggestions mode, trigger completion
      if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        CURRENT_SUGGESTION_INDEX=0
        zle -R
        [[ -n "$BUFFER" ]] && _zsh_completion
      fi
    fi
}

_zsh_on_upkey_pressed() {
  ARROW_KEY_PRESSED=true
  POSTDISPLAY=""
    info "[ZSH EVENT] Up key pressed"
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
    BUFFER="@2501 $_AGENTIC_SUGGESTION"
    tput sc     # Save the current cursor position
    clear_lines # Clear previous output lines
    tput rc     # Restore the cursor to the previously saved position
    zle .accept-line
}

_zsh_on_buffer_modified(){
    info "[ZSH EVENT] Buffer modified"
    _check_buffer_change
    # If we are in suggestion mode, trigger completion
    # But only if the buffer is not empty and an arrow key was not pressed
    if [[ $IN_SUGGESTION_MODE == "true" ]] && [[ -n "$BUFFER" ]] && [[ "$ARROW_KEY_PRESSED" == "false" ]]; then
        _zsh_completion
    fi

    # Reset the arrow key flag
    ARROW_KEY_PRESSED=false
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

# Clear POSTDISPLAY when typing starts
function clear_postdisplay() {
  if [[ -z $BUFFER ]]; then
    POSTDISPLAY=''
  fi
  zle .self-insert "$@"
  _zsh_completion
}
zle -N self-insert clear_postdisplay

bindkey "^[^?" clear_postdisplay  # Binds to all printable characters

# Store the original key binding events.
_up_key_binding=$(bindkey "${key[Up]}" | awk '{$1=""; print substr($0,2)}')
_down_key_binding=$(bindkey "${key[Down]}" | awk '{$1=""; print substr($0,2)}')

bindkey "^M" _zsh_execute_line  # Bind Enter key to _zsh_execute_line
#bindkey "^I" _zsh_accept_line # Bind Tab key to _zsh_accept_line
[[ -n "${key[Up]}"   ]] && bindkey "${key[Up]}"   _zsh_on_upkey_pressed
[[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" _zsh_on_downkey_pressed

# Keep track of the last buffer
LAST_BUFFER=""

# When the line is initialized
_zsh_on_line_init() {
    info "[ZSH EVENT] Line init | ARROW_KEY_PRESSED: $ARROW_KEY_PRESSED"
    ARROW_KEY_PRESSED=false
    _reset_state
}

# When the line is finished
_zsh_on_line_pre_redraw() {
    info "[ZSH EVENT] Line pre redraw | ARROW_KEY_PRESSED: $ARROW_KEY_PRESSED"
    _check_buffer_change
    ARROW_KEY_PRESSED=false
}

add-zle-hook-widget line-init _zsh_on_line_init # When the line is initialized
#add-zle-hook-widget line-finish _zsh_on_line_finish # when the line is finished
add-zle-hook-widget keymap-select _zsh_on_buffer_modified

add-zle-hook-widget line-pre-redraw _zsh_on_line_pre_redraw

zle -N _zsh_execute_with_2501

bindkey "^J" _zsh_execute_with_2501        # Control+J

# Register the paste handler
zle -N bracketed-paste _zsh_handle_paste

# Enable suggestions by default
_toggle_suggestions_mode "$BUFFER"