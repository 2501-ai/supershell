#!/bin/bash
# ANSI escape code utilities

# Colors
GRAY='\033[90m'
RED='\033[91m'
DARK_GRAY='\033[38;5;240m'
RESET='\033[0m'

# Cursor movement
clear_lines() {
    printf '\033[J' # Clear all under the cursor
}

save_cursor_position() {
    printf '\033[s'
}

restore_cursor_position() {
    printf '\033[u'
}

move_cursor_up() {
    printf '\033[%dA' "$1"  # Move up $1 lines
}

move_cursor_start() {
    printf '\r'  # Move to the start of the current line
}

move_cursor_down() {
    printf '\033[%dB' "$1"  # Move down $1 lines
}

clear_current_line() {
    printf '\033[2K'  # Clears the entire line
    printf '\r'       # Moves the cursor back to the start of the line
}