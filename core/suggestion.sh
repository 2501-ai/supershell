#!/bin/bash
# Suggestion fetching and handling

# Sanitize function for JSON strings
_sanitize_for_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}
LAST_SUGGESTIONS=()

# Parse the raw array string into an array
# Array string looks like `[
#   "git status",
#   "git stash",
#   "git show",
#   "git submodule",
#   "git svn"
# ]`
_parse_array() {
    local raw_arr="$1"
    local arr=()
    local IFS=$'\n' # Set the Internal Field Separator to newline
    for item in $(echo "$raw_arr"); do
        # info "adding item: $item"
        arr+=("$item")
        echo "$item"
    done
    # return the array variable containing strings
    echo "${arr[*]}"
}

# Example of a more robust HTTP client function
_fetch_suggestions() {
    local query="$1"
    local sysinfo=$(_get_system_info)
    local curr_path=$(pwd)
    local files=$(_get_ls)
    
    # Sanitize all inputs
    query="$(_sanitize_for_json "$query")"
    sysinfo="$(_sanitize_for_json "$sysinfo")"
    curr_path="$(_sanitize_for_json "$curr_path")"
    files="$(_sanitize_for_json "$files")"

    # debug "Fetching suggestions for query: '$query'"

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
    raw_arr=$(echo "$response" | jq -r '.commands[]')
    # info "raw_arr: $raw_arr"
    # declare -a new_arr=($raw_arr[*])
    # info "new_arr: ${new_arr[*]}"
    # # info "new_arr 0 : ${new_arr[0]}"
    # info "new_arr 1 : ${new_arr[1]}"
    local IFS=$'\n' # Set IFS to newline for array parsing

    # Initialize the suggestions array
    LAST_SUGGESTIONS=()

    # Loop through each line of raw_arr properly
    local _count=0
    for item in $(echo "$raw_arr"); do
        # Debug: Check each item before adding to array
        info "Item: '$item'"

        # Trim leading/trailing spaces and newline characters
        item=$(echo "$item" | xargs)

        # Only add non-empty items to the array
        if [[ -n "$item" ]]; then
            LAST_SUGGESTIONS+=("$item")
        fi
    done
    info "Fetched Suggestions: $LAST_SUGGESTIONS"
    CURRENT_SUGGESTION_INDEX=1  # Reset selection index
    _display_suggestions ${LAST_SUGGESTIONS[*]}
}