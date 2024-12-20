#!/bin/bash
# Suggestion fetching and handling
set -a # Automatically export all variables

_FETCHED_SUGGESTIONS=()
_AGENTIC_SUGGESTION=""

# Sanitize function for JSON strings
_sanitize_string() {
    sed 's/\\/\\\\/g; s/"/\\"/g' <<< "$1"
}

# ==============================================================================
# Fetch suggestions from the API
# ==============================================================================
_fetch_suggestions() {
     info "[SUGGESTION] Fetching suggestions started"
    local query="$1"
     info "[SUGGESTION] Query: $query"
    
    local sysinfo=$(_get_system_info)
    local curr_path=$(pwd)
    local files=$(_get_ls)
    
     info "[SUGGESTION] Got system info and context"
    
    # Sanitize all inputs using the actual sanitization function
    query="$(_sanitize_string "$query")"
    sysinfo="$(_sanitize_string "$sysinfo")"
    curr_path="$(_sanitize_string "$curr_path")"
    files="$(_sanitize_string "$files")"
    
    info "[SUGGESTION] Making API request..."
    local json_payload="{
        \"query\": \"$query\",
        \"systemInfos\": \"$sysinfo\",
        \"pwd\": \"$curr_path\",
        \"ls\": \"$files\"}"

    local response
    info "[SUGGESTION] JSON payload: $json_payload"
    # Add timeout and retry logic
    for _ in {1..3}; do
        response=$(curl -s -m 2 \
            -X POST \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
         "$API_ENDPOINT")
            
        if [ -n "$response" ]; then
            info "[SUGGESTION] Got API response"
            # Validate JSON response
            if echo "$response" | jq -e . >/dev/null 2>&1; then
                break
            else
                info "[SUGGESTION] Invalid JSON response"
                response=""
            fi
        fi
        sleep 0.5
    done
    
    # Clear loading indicator and display suggestions
    raw_arr=$(echo "$response" | jq -r '.commands[]')
    # info "raw_arr: $raw_arr"
    local IFS=$'\n' # Set IFS to newline for array parsing

    info "API Suggestions: ${raw_arr[*]}"

    # Initialize the suggestions array
    _FETCHED_SUGGESTIONS=()

    _AGENTIC_SUGGESTION=$(echo "$response" | jq -r '.prompts[0]')

    # Loop through each line of raw_arr properly
    local _count=0
    for item in $(echo "$raw_arr"); do
        # Verify that the length of the array is less than the maximum suggestions
        if [ $_count -ge "$MAX_SUGGESTIONS" ]; then
            break
        fi
        # Debug: Check each item before adding to array
        info "Item: '$item'"

        # Trim leading/trailing spaces and newline characters, keeping quotes intact
        item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Only add non-empty items to the array
        if [[ -n "$item" ]]; then
            _FETCHED_SUGGESTIONS+=("$item")
        fi
    done
    info "Fetched Suggestions: ${_FETCHED_SUGGESTIONS[*]}"

    CURRENT_SUGGESTION_INDEX=0  # Reset selection index
    _store_suggestions
    _display_suggestions
}
# ==============================================================================
# Hack to store and read suggestions from a file because zsh/bash arrays are
# not stored correctly in memory. This is a workaround to persist suggestions.
# ==============================================================================

# Store the suggestions in a tmp file.
_store_suggestions() {
    local shell_tmp_file="/tmp/2501/shell_suggestions"
    mkdir -p "$(dirname "$tmp_file")"

    local agent_tmp_file="/tmp/2501/agentic_suggestion"
    mkdir -p "$(dirname "$tmp_file")"

    
    # Clear the file first
    : > "$shell_tmp_file"
    : > "$agent_tmp_file"
    
    # Store each suggestion on a new line
    printf '%s\n' "${_FETCHED_SUGGESTIONS[@]}" > "$shell_tmp_file"
    printf '%s\n' "$_AGENTIC_SUGGESTION" > "$agent_tmp_file"
}

# Read the suggestions from the tmp file and store in a global array.
_read_suggestions() {
    local shell_tmp_file="/tmp/2501/shell_suggestions"
    local agent_tmp_file="/tmp/2501/agentic_suggestion"

    if [[ ! -f "$shell_tmp_file" ]]; then
        _FETCHED_SUGGESTIONS=()
        _AGENTIC_SUGGESTION=""
        return
    fi
    
    # Read the file into array, compatible with both bash and zsh
    if [ -n "$ZSH_VERSION" ]; then
        # ZSH way
        _FETCHED_SUGGESTIONS=("${(@f)$(<$shell_tmp_file)}")
        _AGENTIC_SUGGESTION=$(<"$agent_tmp_file")
    else
        # Bash way
        mapfile -t _FETCHED_SUGGESTIONS < "$shell_tmp_file"
        mapfile -t _AGENTIC_SUGGESTION < "$agent_tmp_file"
    fi
}

_clear_suggestions() {
    _FETCHED_SUGGESTIONS=()
    _AGENTIC_SUGGESTION=""
    _store_suggestions
}