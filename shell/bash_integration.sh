#!/bin/bash
# Bash-specific integration with ZSH-like features

# Handle CTRL+C
trap '_cleanup_debounce' SIGINT

# Enable forward-char for proper cursor movement
bind '"\e[C": forward-char'

# Flag to control completion triggering
TRIGGER_COMPLETION=true
LAST_LINE=""

# Create a function to handle each character typed
_bash_self_insert() {
    local line="$READLINE_LINE"
    
    if [[ "$line" != "$LAST_LINE" ]]; then
        LAST_LINE="$line"
        
        if [[ ${#line} -ge 2 ]]; then
            _fetch_suggestions "$line"
        fi
    fi
}

# Navigation functions
_bash_select_next() {
    TRIGGER_COMPLETION=false
    _select_next_suggestion
    READLINE_LINE="$CURRENT_SUGGESTION"
    READLINE_POINT=${#READLINE_LINE}
}

_bash_select_prev() {
    TRIGGER_COMPLETION=false
    _select_prev_suggestion
    READLINE_LINE="$CURRENT_SUGGESTION"
    READLINE_POINT=${#READLINE_LINE}
}

# Execute the currently selected suggestion
_bash_execute() {
    if [ -n "$CURRENT_SUGGESTION" ]; then
        READLINE_LINE="$CURRENT_SUGGESTION"
        READLINE_POINT=${#READLINE_LINE}
    fi
}

# Handle Enter key
_bash_accept_line() {
    _cleanup_debounce
    READLINE_LINE="$READLINE_LINE"
    LAST_LINE=""  # Reset last line on enter
    CURRENT_SUGGESTION=""  # Reset current suggestion
    CURRENT_SUGGESTION_INDEX=0  # Reset index
}

# Bind keys for navigation
bind -x '"\e[A": _bash_select_prev'    # Up arrow
bind -x '"\e[B": _bash_select_next'    # Down arrow
bind -x '"\t": _bash_execute'          # Tab key
bind -x '"\C-m": _bash_accept_line'    # Enter key

# Enable readline features
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set menu-complete-display-prefix on'

# Set up key event handling
bind 'set keymap emacs'
bind 'set convert-meta on'
bind 'set input-meta on'
bind 'set output-meta on'

# Create a wrapper for self-insert
_bash_key_handler() {
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$1${READLINE_LINE:$READLINE_POINT}"
    ((READLINE_POINT++))
    _bash_self_insert
}

# Bind common keys for input
for c in {a..z}; do
    bind -x "\"$c\": '_bash_key_handler $c'"
    bind -x "\"${c^}\": '_bash_key_handler ${c^}'"  # Capital letters
done

for n in {0..9}; do
    bind -x "\"$n\": '_bash_key_handler $n'"
done

# Common special characters
for char in - _ . /; do
    bind -x "\"$char\": '_bash_key_handler $char'"
done