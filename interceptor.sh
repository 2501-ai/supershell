#!/bin/bash
set +m

API_KEY="2501_ak_0bf83450ffe77028656b09226742f3aad8eae7a19b6cffbcbaf735c7d42072e8aed87b9de3e806ac35bbcaa9a63cb7228a44869974db51c7ccc8da33f10ba62345ecf7020a097fc071c5905275c3ff12"
CURRENT_SUGGESTION=""
DEBOUNCE_DELAY=2  # seconds
LAST_QUERY=""
DEBOUNCE_TIMER_PID=""

# Get prompt info without relying on git_prompt_info
_get_prompt_info() {
    local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local git_info=""
    if [ -n "$git_branch" ]; then
        git_info=" ($git_branch)"
    fi
    
    local dir="${PWD/#$HOME/~}"
    echo "$dir$git_info"
}

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

_show_loading() {
    # Clear any existing suggestions first
    # printf '\r\033[K'  # Clear current line
    # printf '\n\033[K'  # Clear line below
    # printf '\n\033[K'  # Clear second line below
    # printf '\033[2A'   # Move cursor back up two lines
    
    # Print the current input
    # printf '%s' "$READLINE_LINE"
    
    # Show loading indicator below the input
    # printf '\n\033[K\033[90m⋯ fetching suggestions...\033[0m'
    
    # Move cursor back to original position
    # printf '\033[1A\r'
    # printf '\033[%dC' "${#READLINE_LINE}"
}

_handle_suggestion_response() {
    local response="$1"
    
    if ! echo "$response" | jq empty 2>/dev/null; then
        _display_error "Invalid response format"
        return 1
    fi
    
    local suggestion=$(echo "$response" | jq -r '.suggestion // empty')
    if [ -n "$suggestion" ]; then
        _display_suggestion "$suggestion"
    fi
}

_display_suggestions() {
    local response="$1"
    
    # Clear previous loading indicator/suggestions
    # printf '\r\033[K'  # Clear current line
    # printf '\n\033[K'  # Clear line below
    # printf '\n\033[K'  # Clear second line below
    printf '\033[2A'   # Move cursor back up two lines
    
    if echo "$response" | jq empty 2>/dev/null; then
        CURRENT_SUGGESTION=$(echo "$response" | jq -r '.commands[0]' 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_SUGGESTION" ] && [ "$CURRENT_SUGGESTION" != "null" ]; then
            # Print the current input
            printf '%s' "$READLINE_LINE"
            
            # Print suggestions with arrow and execution hint
            printf '\n\033[K\033[90m→ %s\033[0m' "$CURRENT_SUGGESTION"
            printf '\n\033[K\033[38;5;240m[TAB to execute]\033[0m'
            
            # Move cursor back to original position
            # printf '\033[2A\r'
            printf '\033[%dC' "${#READLINE_LINE}"
        fi
    else
        # Handle error case
        printf '%s' "$READLINE_LINE"
        printf '\n\033[K\033[91mError fetching suggestions\033[0m'
        printf '\033[1A\r'
        printf '\033[%dC' "${#READLINE_LINE}"
    fi
}

_get_system_info() {
    os=$(uname -a)
    if [ "$(uname)" = "Darwin" ]; then
        ram=$(sysctl -n hw.memsize | awk '{ printf "%.2fGB", $1/1024/1024/1024 }')
        cpu=$(sysctl -n machdep.cpu.brand_string)
    else
        ram=$(grep MemTotal /proc/meminfo | awk '{printf "%.2fGB", $2/1024/1024}')
        cpu=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    fi
    echo "$os - RAM: $ram - CPU: $cpu"
}

_get_ls() {
    ls -1a | tr '\n' ',' | sed 's/,$//'
}
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
         "http://localhost:1337/api/v1/completion" || echo "")
            
        if [ -n "$response" ]; then
            break
        fi
        sleep 0.5
    done
    
    # Clear loading indicator and display suggestions
    _display_suggestions "$response"

    # echo "$response"
}

# Get prompt length for cursor positioning
_get_prompt_length() {
    local prompt_str=$(_get_prompt_info)
    # Strip ANSI escape codes if present
    local clean_prompt_str=$(echo "$prompt_str" | sed 's/\x1b\[[0-9;]*m//g')
    echo ${#clean_prompt_str}
}

prompt_length=$(_get_prompt_length)

_universal_complete() {
    local current_word="$1"
    local cursor_pos="$2"
    
    if [ -z "$current_word" ]; then
        # Clear suggestions
        printf '\r\033[K'
        printf '\n\033[K'
        printf '\n\033[K'
        printf '\033[2A\r'
        CURRENT_SUGGESTION=""
        return
    fi
    
    if [ ${#current_word} -ge 2 ]; then
        _debounced_suggest "$current_word"
    fi
}

_execute_suggestion() {
    if [ -n "$CURRENT_SUGGESTION" ]; then
        local prompt_str=$(_get_prompt_info)
        # Clear current line and suggestions
        echo -ne "\033[K"  # Clear current line
        echo -ne "\n\033[K"  # Clear first suggestion
        echo -ne "\n\033[K"  # Clear second suggestion
        echo -ne "\033[2F"  # Move back up two lines
        
        # Execute the command
        eval "$CURRENT_SUGGESTION"
        CURRENT_SUGGESTION=""
    fi
}

# For bash
if [ -n "$BASH_VERSION" ]; then
    bind '"\e[C": forward-char'
    # Handle CTRL+C
    trap '_cleanup_debounce' SIGINT
    
    # Handle Enter key
    bind -x '"\C-m": "_cleanup_debounce; READLINE_LINE=$READLINE_LINE\n"'
    
    _bash_complete() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            _execute_suggestion
        else
            _universal_complete "$READLINE_LINE" "$READLINE_POINT"
        fi
    }
    bind -x '"\t": _bash_complete'
fi

# For zsh
if [ -n "$ZSH_VERSION" ]; then
    autoload -U add-zle-hook-widget
      
    # Handle CTRL+C
    TRAPINT() {
        _cleanup_debounce
        return $(( 128 + $1 ))
    }
    
    # Handle Enter key
    _zsh_accept_line() {
        _cleanup_debounce
        zle .accept-line
    }

    _zsh_completion() {
        _universal_complete "$BUFFER" "$CURSOR"
        zle -R
    }
    _zsh_execute() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            _execute_suggestion
            # zle reset-prompt # This line resets the prompt after executing the command
        fi
    }
    zle -N _zsh_completion
    zle -N _zsh_execute
    zle -N accept-line _zsh_accept_line
    add-zle-hook-widget line-pre-redraw _zsh_completion
    bindkey '^I' _zsh_execute
fi