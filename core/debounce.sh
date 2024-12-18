#!/bin/bash
# Debounce functionality

echo "[DEBOUNCE] Initializing debounce module..."

_cleanup_debounce() {
    echo "[DEBOUNCE] Cleaning up debounce"
    if [ -n "$TIMER_PID" ]; then
        echo "[DEBOUNCE] Killing timer process: $TIMER_PID"
        kill "$TIMER_PID" 2>/dev/null
        TIMER_PID=""
    fi
}

_debounced_suggest() {
    echo "[DEBOUNCE] Debouncing suggestion request"
    local query="$1"
    
    _cleanup_debounce
    
    echo "[DEBOUNCE] Setting up new timer"
    (
        sleep "$DELAY"
        _fetch_suggestions "$query"
    ) &
    TIMER_PID=$!
    echo "[DEBOUNCE] New timer PID: $TIMER_PID"
}