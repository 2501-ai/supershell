#!/bin/bash
# Suggestion fetching and handling

echo "[SUGGESTION] Initializing suggestion module..."

# Debug wrapper for sanitization
_sanitize_for_json() {
    echo "[SUGGESTION] Sanitizing input for JSON" >&2
    _sanitize_string "$1"
}

# Actual sanitization function
_sanitize_string() {
    sed 's/\\/\\\\/g; s/"/\\"/g' <<< "$1"
}

LAST_SUGGESTIONS=()
echo "[SUGGESTION] Initialized empty suggestions array"

# Example of a more robust HTTP client function
_fetch_suggestions() {
    echo "[SUGGESTION] Fetching suggestions started"
    local query="$1"
    echo "[SUGGESTION] Query: $query"
    
    local sysinfo=$(_get_system_info)
    local curr_path=$(pwd)
    local files=$(_get_ls)
    
    echo "[SUGGESTION] Got system info and context"
    
    # Sanitize all inputs using the actual sanitization function
    query="$(_sanitize_string "$query")"
    sysinfo="$(_sanitize_string "$sysinfo")"
    curr_path="$(_sanitize_string "$curr_path")"
    files="$(_sanitize_string "$files")"
    
    echo "[SUGGESTION] Making API request..."
    local json_payload="{
        \"query\": \"$query\",
        \"systemInfos\": \"$sysinfo\",
        \"pwd\": \"$curr_path\",
        \"ls\": \"$files\"}"

    local response
    echo "[SUGGESTION] JSON payload: $json_payload"
    # Add timeout and retry logic
    for i in {1..3}; do
        echo "[SUGGESTION] API attempt $i"
        response=$(curl -s -m 2 \
            -X POST \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
         $API_ENDPOINT || echo "")
            
        if [ -n "$response" ]; then
            echo "[SUGGESTION] Got API response"
            # Validate JSON response
            if echo "$response" | jq -e . >/dev/null 2>&1; then
                break
            else
                echo "[SUGGESTION] Invalid JSON response"
                response=""
            fi
        fi
        sleep 0.5
    done
    
    echo "[SUGGESTION] Processing response..."
    if [ -n "$response" ]; then
        # Check if commands array exists and is not null
        if echo "$response" | jq -e '.commands' >/dev/null 2>&1; then
            LAST_SUGGESTIONS=()
            
            while IFS= read -r item; do
                if [[ -n "$item" && "$item" != "null" ]]; then
                    echo "[SUGGESTION] Adding suggestion: $item"
                    LAST_SUGGESTIONS+=("$item")
                fi
            done < <(echo "$response" | jq -r '.commands[]' 2>/dev/null)
            
            echo "[SUGGESTION] Total suggestions: ${#LAST_SUGGESTIONS[@]}"
            if [ ${#LAST_SUGGESTIONS[@]} -gt 0 ]; then
                CURRENT_SUGGESTION_INDEX=0
                _display_suggestions "${LAST_SUGGESTIONS[@]}"
            else
                echo "[SUGGESTION] No valid suggestions in response"
            fi
        else
            echo "[SUGGESTION] No commands array in response"
        fi
    else
        echo "[SUGGESTION] No valid response received"
    fi
}