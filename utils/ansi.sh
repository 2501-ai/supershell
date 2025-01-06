#!/bin/bash
# ANSI escape code utilities
# Colors
GRAY='\033[90m'
RED='\033[91m'
DARK_GRAY='\033[38;5;240m'
RESET='\033[0m'
# Cursor movement
clear_lines() {
    # $TERM_PROGRAM on vscode = vscode
    # $TERM_PROGRAM on MacOS terminal = Apple_Terminal
    # $TERM_PROGRAM on iTerm = iTerm.app
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
        printf '\n\033[K'  # Clear suggestion line
    fi

    # Clear lines based on the "$MAX_SUGGESTIONS" variable
    for _ in $(seq 1 "$MAX_SUGGESTIONS"); do
        printf '\n\033[K'  # Clear suggestion line
    done

    printf '\n\033[K'  # Clear hint line

    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
        printf '\033[6A'  # Clear suggestion line
    else
        printf '\033[5A'   # Move cursor back up five lines
    fi

}

clear_lines_force() {
    printf '\033[J\n'   # Clear all lines
}

restore_cursor() {
#    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
#        tput rc # calling this in iTerm leads to cursor jumping/flickering
#    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
#        tput rc
#    else
##        printf '\033[u'
#        tput rc
#    fi
    tput rc
}