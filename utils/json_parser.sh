#!/bin/bash
# In-house JSON parser to replace jq dependency
# Handles basic JSON parsing for command suggestions and prompts

# Sanitize function for JSON strings (reused from suggestion.sh)
_sanitize_string() {
    sed 's/\\/\\\\/g; s/"/\\"/g' <<< "$1"
}

# Validate if a string is valid JSON
# Returns 0 for valid JSON, non-zero for invalid
json_validate() {
    local input="$1"
    # Check if input starts with { and ends with }
    if [[ ! "$input" =~ ^\{.*\}$ ]]; then
        return 1
    fi
    
    # Check for balanced braces and brackets
    local open_braces=0
    local open_brackets=0
    local in_string=false
    local escaped=false
    
    for (( i=0; i<${#input}; i++ )); do
        local char="${input:$i:1}"
        
        if [[ "$in_string" == "true" ]]; then
            if [[ "$escaped" == "false" && "$char" == '"' ]]; then
                in_string=false
            elif [[ "$escaped" == "false" && "$char" == '\' ]]; then
                escaped=true
            else
                escaped=false
            fi
            continue
        fi
        
        case "$char" in
            '{') ((open_braces++)) ;;
            '}') ((open_braces--)) ;;
            '[') ((open_brackets++)) ;;
            ']') ((open_brackets--)) ;;
            '"') in_string=true ;;
        esac
        
        if (( open_braces < 0 || open_brackets < 0 )); then
            return 1
        fi
    done
    
    # Check if all braces and brackets are balanced
    [[ "$open_braces" == "0" && "$open_brackets" == "0" ]] && return 0 || return 1
}

# Extract array elements from a JSON field
# Args:
#   $1: JSON string
#   $2: field name (e.g. "commands")
# Output: One array element per line
json_get_array() {
    local input="$1"
    local field="$2"
    
    # Extract the array content between [ and ] for the specified field
    local array_content
    array_content=$(echo "$input" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\[[^]]*\]" | grep -o '\[.*\]')
    
    # If no array found, return empty
    if [[ -z "$array_content" ]]; then
        return 0
    fi
    
    # Remove [ and ] from array content
    array_content="${array_content#[}"
    array_content="${array_content%]}"
    
    # Split elements and process each one
    local IFS=','
    local elements=($array_content)
    
    # Output each element, stripped of whitespace and quotes
    for element in "${elements[@]}"; do
        # Trim whitespace and quotes
        element=$(echo "$element" | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//')
        echo "$element"
    done
}

# Get a single value from JSON
# Args:
#   $1: JSON string
#   $2: field path (e.g. "prompts[0]" or "field")
# Output: Single value
json_get_value() {
    local input="$1"
    local field_path="$2"
    
    # Check if we're accessing an array element
    if [[ "$field_path" =~ ^([^[]+)\[([0-9]+)\]$ ]]; then
        local field_name="${BASH_REMATCH[1]}"
        local index="${BASH_REMATCH[2]}"
        
        # Get array elements
        local elements
        mapfile -t elements < <(json_get_array "$input" "$field_name")
        
        # Return element at index if it exists
        if (( index < ${#elements[@]} )); then
            echo "${elements[$index]}"
        fi
    else
        # Extract simple field value
        local value
        value=$(echo "$input" | grep -o "\"$field_path\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | grep -o ':"[^"]*"' | cut -d'"' -f2)
        echo "$value"
    fi
}
