#!/bin/bash

# History Navigation Utility
#
# This script provides enhanced history navigation for both ZSH and Bash shells.
# It tracks navigation position, logs movements, and provides visual feedback.
#
# Features:
# - Up/Down arrow navigation
# - Position tracking
# - Movement logging
# - Start/End detection
# - Shell compatibility (ZSH/Bash)

LOG_FILE="$HOME/history_navigation.log"
POSITION_FILE="/tmp/shell_history_position"
HISTORY_POSITION=0

# Logs a message with timestamp to the log file
# @param {string} message - The message to log
# @shell ZSH, BASH
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
}

# Saves current position to temporary file
# @shell ZSH, BASH
save_position() {
    echo "$HISTORY_POSITION" >"$POSITION_FILE"
    log_message "Position saved: $HISTORY_POSITION"
}

# Retrieves command at specific position
# @param {number} pos - History position to retrieve
# @returns {string} Command at position
# @shell ZSH, BASH
get_command() {
    if [[ -n "$ZSH_VERSION" ]]; then
        fc -l -n "$1" "$1" 2>/dev/null
    else
        history | grep "^[ ]*${1}[ ]*" | sed 's/^[ ]*[0-9]*[ ]*//'
    fi
}

# Gets last index in history
# @returns {number} Last history index
# @shell ZSH, BASH
get_last_index() {
    if [[ -n "$ZSH_VERSION" ]]; then
        fc -l -1 | awk '{print $1}'
    else
        history 1 | awk '{print $1}'
    fi
}

# Cross-shell print function
# @param {string} text - Text to print
# @shell ZSH, BASH
shell_print() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "$1"
    else
        echo -e "$1"
    fi
}

# Handles up arrow navigation
# @shell ZSH, BASH
custom_up() {
    local last_index
    last_index=$(get_last_index)
    local is_at_start=false
    local is_at_end=false

    if [[ $HISTORY_POSITION -eq 0 ]]; then
        HISTORY_POSITION=$last_index
    else
        if [[ $HISTORY_POSITION -gt 1 ]]; then
            ((HISTORY_POSITION--))
        fi
    fi

    [[ $HISTORY_POSITION -eq 1 ]] && is_at_start=true
    [[ $HISTORY_POSITION -ge $last_index ]] && is_at_end=true

    local current_cmd
    current_cmd=$(get_command "$HISTORY_POSITION")

    shell_print "\n=== History Navigation ==="
    shell_print "▲ UP: $HISTORY_POSITION / $last_index"
    shell_print "Current command: ${current_cmd:-No command at this position}"

    if [[ $is_at_start == true ]]; then
        shell_print "⚠️  Start of history reached!"
    fi

    if [[ -n "$ZSH_VERSION" ]]; then
        zle up-line-or-history
        zle reset-prompt
    else
        READLINE_LINE="$current_cmd"
        READLINE_POINT=${#READLINE_LINE}
    fi

    log_message "UP: position $HISTORY_POSITION/$last_index - cmd: ${current_cmd:-No command} [START:$is_at_start|END:$is_at_end]"
    save_position
}

# Handles down arrow navigation
# @shell ZSH, BASH
custom_down() {
    local last_index
    last_index=$(get_last_index)
    local is_at_start=false
    local is_at_end=false

    if [[ $HISTORY_POSITION -lt $last_index ]]; then
        ((HISTORY_POSITION++))
    fi

    [[ $HISTORY_POSITION -eq 1 ]] && is_at_start=true
    [[ $HISTORY_POSITION -ge $last_index ]] && is_at_end=true

    local current_cmd
    current_cmd=$(get_command "$HISTORY_POSITION")

    shell_print "\n=== History Navigation ==="
    shell_print "▼ DOWN: $HISTORY_POSITION / $last_index"
    shell_print "Current command: ${current_cmd:-No command at this position}"

    if [[ $is_at_end == true ]]; then
        shell_print "⚠️  End of history reached!"
    fi

    if [[ -n "$ZSH_VERSION" ]]; then
        zle down-line-or-history
        zle reset-prompt
    else
        READLINE_LINE="$current_cmd"
        READLINE_POINT=${#READLINE_LINE}
    fi

    log_message "DOWN: position $HISTORY_POSITION/$last_index - cmd: ${current_cmd:-No command} [START:$is_at_start|END:$is_at_end]"
    save_position
}

if [[ -n "$ZSH_VERSION" ]]; then
    zle -N custom_up
    zle -N custom_down
    bindkey '^[OA' custom_up
    bindkey '^[OB' custom_down
    bindkey '^[[A' custom_up
    bindkey '^[[B' custom_down
elif [[ -n "$BASH_VERSION" ]]; then
    bind -x '"\e[A": custom_up'
    bind -x '"\e[B": custom_down'
fi
