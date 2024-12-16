#!/bin/bash
# Debouncing functionality

LAST_QUERY=""
DEBOUNCE_TIMER_PID=""

echo "Debounce loaded"
echo "Delay is $DEBOUNCE_DELAY"
echo "Timer PID is $DEBOUNCE_TIMER_PID"

_debounced_suggest() {
   local query="$1"
    LAST_QUERY="$query"
    
    # Kill any existing timer
    if [ -n "$DEBOUNCE_TIMER_PID" ]; then
        kill "$DEBOUNCE_TIMER_PID" 2>/dev/null || true
    fi
    
    # Start a new timer
    (
        sleep "$DEBOUNCE_DELAY"
        # Only fetch if this is still the latest query
        if [ "$LAST_QUERY" = "$query" ]; then
            _fetch_suggestions "$query"
        fi
    ) & DEBOUNCE_TIMER_PID=$!
}

_cleanup_debounce() {
    if [ -n "$DEBOUNCE_TIMER_PID" ]; then
        kill "$DEBOUNCE_TIMER_PID" 2>/dev/null || true
        DEBOUNCE_TIMER_PID=""
    fi
    CURRENT_SUGGESTION=""
}