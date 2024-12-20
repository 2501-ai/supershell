#!/bin/bash
# Terminal control utilities

# Colors using tput
GRAY=$(tput setaf 245)    # Light gray
RED=$(tput setaf 1)       # Red
DARK_GRAY=$(tput setaf 240)  # Dark gray
RESET=$(tput sgr0)        # Reset all attributes

# Cursor movement
clear_lines() {
    # $TERM_PROGRAM on vscode = vscode
    # $TERM_PROGRAM on MacOS terminal = Apple_Terminal
    # $TERM_PROGRAM on iTerm = iTerm.app

    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
        printf '\n'
        tput el  # Clear to end of line
    fi
    
    # Clear lines based on the "$MAX_SUGGESTIONS" variable
    for _ in $(seq 1 "$MAX_SUGGESTIONS"); do
        printf '\n'
        tput el  # Clear to end of line
    done
    
    printf '\n'
    tput el     # Clear to end of line
    tput cuu 5  # Move cursor up 5 lines
}

clear_lines_force() {
    tput ed     # Clear from cursor to end of screen
    printf '\n'
}