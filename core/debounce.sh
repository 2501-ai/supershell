#!/bin/bash
# Debouncing functionality

LAST_QUERY=""
DEBOUNCE_TIMER_PID=""
LAST_CLEANUP=0

# ==============================================================================
# Debounce the suggest function to avoid making too many requests.
# ==============================================================================
_debounced_suggest() {
    local query="$1"
    LAST_QUERY="$query"

    # Periodic cleaning (every 10 seconds)
    local now=$(date +%s)
    if [ $((now - LAST_CLEANUP)) -gt 10 ]; then
        jobs -p | xargs -r kill 2>/dev/null || true
        LAST_CLEANUP=$now
    fi

    # Kill any existing timer
    _cleanup_debounce

    # Start a new timer
    (
        sleep "$DEBOUNCE_DELAY"
        # Only fetch if this is still the latest query
        if [ "$LAST_QUERY" = "$query" ]; then
            _start_loading
            _fetch_suggestions "$query"
            _display_suggestions
        fi
    ) & DEBOUNCE_TIMER_PID=$!

    # Clean up old jobs silently
    { kill $(jobs -p | grep -v $DEBOUNCE_TIMER_PID) 2>/dev/null || true; } 2>/dev/null
}

_cleanup_debounce() {
    if [ -n "$DEBOUNCE_TIMER_PID" ]; then
        kill $DEBOUNCE_TIMER_PID 2>/dev/null || true
        DEBOUNCE_TIMER_PID=""
    fi
}

_suppress_job_messages() {
    (
        set +m
        "$@"
    )
}