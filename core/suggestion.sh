#!/bin/bash
# Suggestion fetching and handling


# Example of a more robust HTTP client function
_fetch_suggestions() {
    local query="$1"
    local sysinfo=$(_get_system_info)
    local curr_path=$(pwd)
    local files=$(_get_ls)
    
    # Show loading indicator before making the request
    # _show_loading

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
            break
        fi
        sleep 0.5
    done
    
    # Clear loading indicator and display suggestions
    _display_suggestions "$response"

    # echo "$response"
}