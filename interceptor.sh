#!/bin/bash
set +m

API_KEY="2501_ak_0bf83450ffe77028656b09226742f3aad8eae7a19b6cffbcbaf735c7d42072e8aed87b9de3e806ac35bbcaa9a63cb7228a44869974db51c7ccc8da33f10ba62345ecf7020a097fc071c5905275c3ff12"
CURRENT_SUGGESTION=""
LAST_QUERY_TIME=0
DEBOUNCE_DELAY=2

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

# Debounced fetch function
_debounced_fetch() {
    local current_time=$(date +%s%N)
    current_time=$(echo "$current_time" | sed 's/[0-9]\{9\}$/.&/')
    
    local time_diff=$(awk -v curr="$current_time" -v last="$LAST_QUERY_TIME" 'BEGIN {printf "%.9f\n", curr - last}')
    
    if (( $(echo "$time_diff > $DEBOUNCE_DELAY" | bc -l) )); then
        LAST_QUERY_TIME=$current_time
        _fetch_completion "$1" "$2" &
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

_fetch_completion() {
    local query="$1"
    local sysinfo=$(_get_system_info)
    local curr_path=$(pwd)
    local files=$(_get_ls)

    local json_payload="{
        \"query\": \"$query\",
        \"systemInfos\": \"$sysinfo\",
        \"pwd\": \"$curr_path\",
        \"ls\": \"$files\"}"

    local response=$(curl -s -m 1 \
        -X POST \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "http://localhost:1337/api/v1/completion")

    if echo "$response" | jq empty 2>/dev/null; then
        CURRENT_SUGGESTION=$(echo "$response" | jq -r '.commands[0]' 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_SUGGESTION" ] && [ "$CURRENT_SUGGESTION" != "null" ]; then
            # Clear any existing suggestions first
            printf '\r\033[K'  # Clear current line
            printf '\n\033[K'  # Clear line below
            printf '\n\033[K'  # Clear second line below
            printf '\033[2A'   # Move cursor back up two lines
            
            # Print the current input
            printf '%s' "$query"
            
            # Print suggestions
            printf '\n\033[K\033[90m→ %s\033[0m' "$CURRENT_SUGGESTION"
            printf '\n\033[K\033[38;5;240m[TAB to execute]\033[0m'
            
            # Move cursor back to original position
            printf '\033[2A\r'
            printf '\033[%dC' "${#query}"
        fi
    fi
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
        # Show loading indicator
        printf '\n\033[K\033[90m⋯\033[0m'
        printf '\033[1A\r'
        printf '\033[%dC' "$cursor_pos"
        
        _debounced_fetch "$current_word" "$cursor_pos"
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
    _zsh_completion() {
        _universal_complete "$BUFFER" "$CURSOR"
        zle -R
    }
    _zsh_execute() {
        if [ -n "$CURRENT_SUGGESTION" ]; then
            _execute_suggestion
            zle reset-prompt
        fi
    }
    zle -N _zsh_completion
    zle -N _zsh_execute
    add-zle-hook-widget line-pre-redraw _zsh_completion
    bindkey '^I' _zsh_execute
fi