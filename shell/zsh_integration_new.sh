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

# State management
CURRENT_SUGGESTION=""
IN_SUGGESTION_MODE=false
IN_HISTORY_MODE=false
TRIGGER_COMPLETION=false

source './zsh_common.sh'

# Navigation in suggestions/history
_zsh_select_next() {
    info "[ZSH] _zsh_select_next called"
    info "[ZSH] Current state: IN_SUGGESTION_MODE=$IN_SUGGESTION_MODE, CURRENT_SUGGESTION_INDEX=$CURRENT_SUGGESTION_INDEX"

    # Si on est en mode suggestion
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        info "[ZSH] Currently in suggestion mode"
        _read_suggestions
        local suggestions_count=${#_FETCHED_SUGGESTIONS[@]}
        info "[ZSH] Number of suggestions: $suggestions_count"

        if (( suggestions_count > 0 )); then
            info "[ZSH] Has suggestions"
            # Initialiser ou incrémenter l'index
            if (( CURRENT_SUGGESTION_INDEX < 0 )); then
                CURRENT_SUGGESTION_INDEX=0
            else
                CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX + 1) % suggestions_count ))
            fi

            # S'assurer que la suggestion n'est pas vide
            CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
            if [[ -n "$CURRENT_SUGGESTION" ]]; then
                info "[ZSH] Selected suggestion: $CURRENT_SUGGESTION (index: $CURRENT_SUGGESTION_INDEX of $((suggestions_count-1)))"
                # Synchroniser le buffer avec la suggestion sélectionnée
                BUFFER="$CURRENT_SUGGESTION"
                CURSOR=$#BUFFER
                _disable_zsh_autosuggestions
                # Utiliser le display unifié
                _display_suggestions
                zle -R
            fi
        fi
        return
    fi

    # Navigation dans l'historique
    info "[ZSH] Trying history navigation"
    local current_buffer="$BUFFER"

    # Sauvegarder le buffer actuel
    local old_buffer="$BUFFER"
    zle .down-line-or-history
    local new_buffer="$BUFFER"

    # Si le buffer n'a pas changé après down-line-or-history, on est à la fin
    if [[ "$old_buffer" == "$new_buffer" ]]; then
        info "[ZSH] Reached end of history (buffer unchanged), switching to suggestions"
        BUFFER="$current_buffer"  # Restaurer le buffer original
        ORIGINAL_BUFFER="$current_buffer"
        IN_SUGGESTION_MODE=true
        IN_HISTORY_MODE=false
        info "[ZSH] Calling universal complete with buffer: '$current_buffer'"
        _universal_complete "$current_buffer"
        CURRENT_SUGGESTION_INDEX=-1
        _display_suggestions
        zle -R
    else
        info "[ZSH] Successfully navigated history"
        IN_HISTORY_MODE=true
        IN_SUGGESTION_MODE=false
        _clear_suggestions
    fi
}

_zsh_select_prev() {
    info "[ZSH] _zsh_select_prev called"
    info "[ZSH] Current state: IN_SUGGESTION_MODE=$IN_SUGGESTION_MODE, CURRENT_SUGGESTION_INDEX=$CURRENT_SUGGESTION_INDEX"

    # Si on est en mode suggestion
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        info "[ZSH] Currently in suggestion mode"
        _read_suggestions
        local suggestions_count=${#_FETCHED_SUGGESTIONS[@]}
        info "[ZSH] Number of suggestions: $suggestions_count"

        if (( suggestions_count > 0 )); then
            info "[ZSH] Has suggestions"
            # Si pas encore de sélection, commencer à la fin
            if (( CURRENT_SUGGESTION_INDEX < 0 )); then
                CURRENT_SUGGESTION_INDEX=$(( suggestions_count - 1 ))
            else
                # Correction: s'assurer qu'on atteint bien toutes les suggestions
                CURRENT_SUGGESTION_INDEX=$(( (CURRENT_SUGGESTION_INDEX - 1 + suggestions_count) % suggestions_count ))
            fi

            # S'assurer que la suggestion n'est pas vide
            CURRENT_SUGGESTION="${_FETCHED_SUGGESTIONS[$CURRENT_SUGGESTION_INDEX]}"
            if [[ -n "$CURRENT_SUGGESTION" ]]; then
                info "[ZSH] Selected suggestion: $CURRENT_SUGGESTION (index: $CURRENT_SUGGESTION_INDEX of $((suggestions_count-1)))"
                BUFFER="$CURRENT_SUGGESTION"
                CURSOR=$#BUFFER
                _display_suggestions
                zle -R
            else
                info "[ZSH] Empty suggestion detected, keeping previous buffer"
            fi
        fi
        return
    fi

    # Navigation normale dans l'historique
    info "[ZSH] Normal history navigation"
    zle .up-line-or-history
}

# Fonction pour nettoyer les suggestions de zsh-autosuggestions
_clear_zsh_autosuggestions() {
    # Vérifie si zsh-autosuggestions est chargé
    if [[ -n "${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE+x}" ]]; then
        # Efface la suggestion actuelle
        _zsh_autosuggest_clear
        # Force le rafraîchissement de l'affichage
        zle -R
    fi
}

# Handle Tab key
_zsh_accept_line() {
    _clear_zsh_autosuggestions

    # Si on est en mode suggestion IA
    if [[ "$IN_SUGGESTION_MODE" == "true" && -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
        IN_SUGGESTION_MODE=false
        _clear_suggestions
        zle .accept-line
        return
    fi

    # Sinon, utiliser la complétion native
    zle .complete-word
}

# Handle Enter key
_zsh_execute_line() {
    if [[ "$IN_SUGGESTION_MODE" == "true" && -n "$CURRENT_SUGGESTION" ]]; then
        BUFFER="$CURRENT_SUGGESTION"
        CURSOR=$#BUFFER
    fi

    _clear_suggestions
    IN_SUGGESTION_MODE=false
    IN_HISTORY_MODE=false
    TRIGGER_COMPLETION=false
    CURRENT_SUGGESTION=""

    zle .accept-line
}

# Completion hook
_zsh_completion() {
    info "[ZSH] Completion hook called with BUFFER: '$BUFFER'"

    # Ne jamais réinitialiser si on est en mode suggestion
    if [[ "$IN_SUGGESTION_MODE" == "true" ]]; then
        info "[ZSH] In suggestion mode, skipping reset"
        _disable_zsh_autosuggestions
        return
    fi

    # Seulement réinitialiser si on n'est pas en mode suggestion et que le buffer est vide
    if [[ -z "$BUFFER" && "$IN_SUGGESTION_MODE" == "false" ]]; then
        info "[ZSH] Empty buffer and not in suggestion mode, resetting state"
        _reset_state
    fi
}

# Detect buffer changes
_check_buffer_change() {
    # Keep track of the last buffer
    if [[ -z "$LAST_BUFFER" ]]; then
        LAST_BUFFER="$BUFFER"
        return
    fi

    # Reset if the buffer is shorter than the last buffer
    if (( ${#BUFFER} < ${#LAST_BUFFER} )); then
        _reset_state
    fi

    LAST_BUFFER="$BUFFER"
}

# Register every deletion widget
zle -N backward-delete-char _handle_backspace
zle -N backward-kill-word _handle_backward_kill_word
zle -N clear-screen _handle_clear_screen

add-zle-hook-widget line-init _handle_redraw
add-zle-hook-widget line-finish _handle_redraw
add-zle-hook-widget line-pre-redraw _handle_redraw
add-zle-hook-widget keymap-select _handle_redraw

# Keep other exising hooks

add-zle-hook-widget line-init _check_buffer_change
add-zle-hook-widget line-finish _check_buffer_change
add-zle-hook-widget keymap-select _check_buffer_change

add-zle-hook-widget line-pre-redraw _zsh_completion

# Register widgets and bind keys
zle -N _zsh_select_next
zle -N _zsh_select_prev
zle -N _zsh_accept_line
zle -N _zsh_execute_line

bindkey "^M" _zsh_execute_line
bindkey "^I" _zsh_accept_line
bindkey "${key[Up]}" _zsh_select_prev
bindkey "${key[Down]}" _zsh_select_next

# Fonction pour nettoyer les suggestions
#_clear_suggestions() {
#    # Si on a des suggestions précédentes, les nettoyer
#    if [[ -n "$_LAST_DISPLAYED_SUGGESTIONS" ]]; then
#        local num_lines=$(echo -n "$_LAST_DISPLAYED_SUGGESTIONS" | wc -l)
#        for ((i=0; i<num_lines; i++)); do
#            tput cuu1   # Monter d'une ligne
#            tput el     # Effacer la ligne
#        done
#        _LAST_DISPLAYED_SUGGESTIONS=""
#    fi
#}
