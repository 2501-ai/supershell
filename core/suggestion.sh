#!/bin/bash
# Suggestion fetching and handling

# Sanitization function
_sanitize_string() {
    sed 's/\\/\\\\/g; s/"/\\"/g' <<< "$1"
}

LAST_SUGGESTIONS=()

# Example of a more robust HTTP client function
_fetch_suggestions() {
    local query="$1"
    
    local sysinfo=$(_get_system_info)
    local curr_path=$(pwd)
    local files=$(_get_ls)
    
    # Sanitize all inputs using the actual sanitization function
    query="$(_sanitize_string "$query")"
    sysinfo="$(_sanitize_string "$sysinfo")"
    curr_path="$(_sanitize_string "$curr_path")"
    files="$(_sanitize_string "$files")"
    
    local json_payload="{
        \"query\": \"$query\",
        \"systemInfos\": \"$sysinfo\",
        \"pwd\": \"$curr_path\",
        \"ls\": \"$files\"}"

    local response
    # Add timeout and retry logic
    for i in {1..3}; do
        response=$(curl -s -m 2 \
            -X POST \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
         $API_ENDPOINT || echo "")
            
        if [ -n "$response" ]; then
            # Validate JSON response
            if echo "$response" | jq -e . >/dev/null 2>&1; then
                break
            else
                response=""
            fi
        fi
        sleep 0.5
    done
    
    if [ -n "$response" ]; then
        # Check if commands array exists and is not null
        if echo "$response" | jq -e '.commands' >/dev/null 2>&1; then
            LAST_SUGGESTIONS=()
            
            while IFS= read -r item; do
                if [[ -n "$item" && "$item" != "null" ]]; then
                    LAST_SUGGESTIONS+=("$item")
                fi
            done < <(echo "$response" | jq -r '.commands[]' 2>/dev/null)
            
            if [ ${#LAST_SUGGESTIONS[@]} -gt 0 ]; then
                CURRENT_SUGGESTION_INDEX=0
                _display_suggestions "${LAST_SUGGESTIONS[@]}"
            fi
        fi
    fi
}