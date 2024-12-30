#!/bin/bash
# In-house JSON parser to replace jq dependency
# Implements a jq-like interface for JSON parsing

# Global variables for json_filter options
declare RAW_OUTPUT
declare VALIDATE_MODE
declare FILTER_EXPR

# Sanitize function for JSON strings
_sanitize_string() {
    sed 's/\\/\\\\/g; s/"/\\"/g' <<< "$1"
}

# Parse command-line options for json_filter
# Returns:
#   Sets global variables for options
_parse_options() {
    RAW_OUTPUT=false
    VALIDATE_MODE=false
    FILTER_EXPR=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--raw-output)
                RAW_OUTPUT=true
                shift
                ;;
            -e|--exit-status)
                VALIDATE_MODE=true
                shift
                ;;
            *)
                if [[ -z "$FILTER_EXPR" ]]; then
                    FILTER_EXPR="$1"
                else
                    echo "Error: Multiple filter expressions provided" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    return 0
}

# DEPRECATED: Use json_filter -e '.' instead
# Validate if a string is valid JSON
# Returns 0 for valid JSON, non-zero for invalid
# This function will be removed in a future version
json_validate() {
    json_filter -e '.' "$1"
}

# DEPRECATED: Use json_filter -r '.field[]' instead
# Extract array elements from a JSON field
# Args:
#   $1: JSON string
#   $2: field name (e.g. "commands")
# Output: One array element per line
# This function will be removed in a future version
json_get_array() {
    json_filter -r ".$2[]" "$1"
}

# DEPRECATED: Use json_filter -r '.field' or '.field[n]' instead
# Get a single value from JSON
# Args:
#   $1: JSON string
#   $2: field path (e.g. "prompts[0]" or "field")
# Output: Single value
# This function will be removed in a future version
json_get_value() {
    json_filter -r ".$2" "$1"
}

# Main JSON filter function with jq-like syntax
# Usage: json_filter [-r] [-e] 'filter_expression' [input_json]
# Examples:
#   json_filter -e '.' "$json"              # Validate JSON
#   json_filter -r '.commands[]' "$json"     # Extract array elements
#   json_filter -r '.prompts[0]' "$json"    # Get specific array element
json_filter() {
    # Parse options
    if ! _parse_options "$@"; then
        return 1
    fi
    
    # Get the JSON input (last argument)
    local json_input="${!#}"
    
    # Handle validation mode (-e)
    if [[ "$VALIDATE_MODE" == "true" ]]; then
        json_validate "$json_input"
        return $?
    fi
    
    # Parse the filter expression
    if [[ "$FILTER_EXPR" == "." ]]; then
        # Return the entire JSON document
        echo "$json_input"
    elif [[ "$FILTER_EXPR" =~ ^\.(.*)\[\]$ ]]; then
        # Array iteration: .field[]
        local field="${BASH_REMATCH[1]}"
        if [[ "$RAW_OUTPUT" == "true" ]]; then
            json_get_array "$json_input" "$field"
        else
            # Add quotes for non-raw output
            while IFS= read -r line; do
                echo "\"$line\""
            done < <(json_get_array "$json_input" "$field")
        fi
    elif [[ "$FILTER_EXPR" =~ ^\.(.*)\[[0-9]+\]$ ]]; then
        # Array indexing: .field[n]
        local value
        value=$(json_get_value "$json_input" "${FILTER_EXPR#.}")
        if [[ -n "$value" ]]; then
            if [[ "$RAW_OUTPUT" == "true" ]]; then
                echo "$value"
            else
                echo "\"$value\""
            fi
        fi
    elif [[ "$FILTER_EXPR" =~ ^\.[^[:space:]]+$ ]]; then
        # Simple field access: .field
        local value
        value=$(json_get_value "$json_input" "${FILTER_EXPR#.}")
        if [[ -n "$value" ]]; then
            if [[ "$RAW_OUTPUT" == "true" ]]; then
                echo "$value"
            else
                echo "\"$value\""
            fi
        fi
    else
        echo "Error: Invalid filter expression: $FILTER_EXPR" >&2
        return 1
    fi
}
