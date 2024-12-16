#!/bin/bash
# ANSI escape code utilities

# Colors
GRAY='\033[90m'
RED='\033[91m'
DARK_GRAY='\033[38;5;240m'
RESET='\033[0m'

# Cursor movement
clear_lines() {
    printf '\r\033[K'  # Clear current line
    printf '\n\033[K'  # Clear line below
    printf '\n\033[K'  # Clear second line below
    printf '\033[2A'   # Move cursor back up two lines
}