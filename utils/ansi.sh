#!/bin/bash
# ANSI escape code utilities

# Colors
GRAY='\033[90m'
RED='\033[91m'
DARK_GRAY='\033[38;5;240m'
RESET='\033[0m'

# Cursor movement
clear_lines() {
    
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
        printf '\n\033[K'  # Clear suggestion line
    fi
    
    # Clear lines based on the "$MAX_SUGGESTIONS" variable
    for _ in $(seq 1 "$MAX_SUGGESTIONS"); do
        printf '\n\033[K'  # Clear suggestion line
    done
    
    printf '\n\033[K'  # Clear hint line
    printf '\033[5A'   # Move cursor back up five lines
}