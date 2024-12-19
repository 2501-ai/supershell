#!/bin/bash
# Debouncing functionality

LAST_QUERY=""
DEBOUNCE_ACTION_PID=""
LAST_KEYSTROKE_TIME=0
MIN_QUERY_LENGTH=2

# ==============================================================================
# Debounce the suggest function to avoid making too many requests.
# ==============================================================================
_debounced_suggest() {
    local query="$1"
    local current_time
    current_time=$(date +%s)

    # Always update the last query
    LAST_QUERY="$query"

    # Skip if query is too short
    if [ ${#query} -lt $MIN_QUERY_LENGTH ]; then
        debug "Query too short, skipping"
        _cleanup_debounce
        return
    fi

    # Kill any existing timer
    if [ -n "$DEBOUNCE_ACTION_PID" ]; then
        kill "$DEBOUNCE_ACTION_PID" 2>/dev/null || true
        DEBOUNCE_ACTION_PID=""
    fi

    # Update last keystroke time
    LAST_KEYSTROKE_TIME=$current_time

    # Start new timer
    (
        local start_time=$LAST_KEYSTROKE_TIME
        
        sleep "$DEBOUNCE_DELAY"
        
        # Only proceed if no new keystrokes during sleep
        if [ "$start_time" = "$LAST_KEYSTROKE_TIME" ] && \
           [ "$LAST_QUERY" = "$query" ]; then
            debug "Executing fetch for: $query"
            _fetch_suggestions "$query"
        else
            debug "Skipping fetch - input changed"
        fi
    ) &
    
    DEBOUNCE_ACTION_PID=$!
}

_cleanup_debounce() {
    if [ -n "$DEBOUNCE_ACTION_PID" ]; then
        kill "$DEBOUNCE_ACTION_PID" 2>/dev/null || true
        DEBOUNCE_ACTION_PID=""
    fi
}

_suppress_job_messages() {
    (
        set +m
        "$@"
    )
}
