#!/bin/bash
set +m

API_KEY="your-api-key-here"
CURRENT_SUGGESTION=""

# Initialize last query time to 0
LAST_QUERY_TIME=0
DEBOUNCE_DELAY=2  # 300ms

# Debounced fetch function
_debounced_fetch() {
    # Get current time in milliseconds
    local current_time=$(date +%s%N)
    current_time=$(echo "$current_time" | sed 's/[0-9]\{9\}$/.&/')  # Convert nanoseconds to seconds
    
    # Calculate time difference in seconds
    local time_diff=$(awk -v curr="$current_time" -v last="$LAST_QUERY_TIME" 'BEGIN {printf "%.9f\n", curr - last}')
    
    # Debug info (optional)
    # echo "Current time: $current_time"
    # echo "Last query time: $LAST_QUERY_TIME"
    # echo "Time difference: $time_diff"
    
    # Compare time difference with debounce delay
    if (( $(echo "$time_diff > $DEBOUNCE_DELAY" | bc -l) )); then
        LAST_QUERY_TIME=$current_time
        _fetch_completion "$1" "$2" &
    else
        # echo "Debounced: Too soon since last call (${time_diff}s < ${DEBOUNCE_DELAY}s)"
    fi
}

_get_system_info() {
    os=$(uname -a)
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        ram=$(sysctl -n hw.memsize | awk '{ printf "%.2fGB", $1/1024/1024/1024 }')
        cpu=$(sysctl -n machdep.cpu.brand_string)
    else
        # Linux
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

    local histfile=""
    if [ -n "$HISTFILE" ] && [ -f "$HISTFILE" ]; then
        histfile="$HISTFILE"
    elif [ -f "$HOME/.zsh_history" ]; then
        histfile="$HOME/.zsh_history"
    elif [ -f "$HOME/.bash_history" ]; then
        histfile="$HOME/.bash_history"
    fi

    local history_lines=""
    if [ -n "$histfile" ]; then
        history_lines=$(tail -n 100 "$histfile" | tr '\n' ' ' | sed 's/"/\\"/g')
    fi

    local json_payload="{
        \"query\": \"$query\",
        \"systemInfos\": \"$sysinfo\",
        \"pwd\": \"$curr_path\",
        \"ls\": \"$files\""
    if [ -n "$history_lines" ]; then
        json_payload="${json_payload}, \"history\": \"$history_lines\""
    fi
    json_payload="${json_payload}}"

    local response=$(curl -s -m 1 \
        -X POST \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "http://localhost:1337/api/v1/completion")

    # Parse JSON and extract commands array
    CURRENT_SUGGESTION=$(echo "$response" | jq -r '.commands[0]')

    if [ -n "$CURRENT_SUGGESTION" ]; then
        # printf '\r\033[K%s' "$current_word"
        printf '\n\033[K\e[90m@2501: %s (press TAB to run)\e[0m' "$CURRENT_SUGGESTION"
        printf '\n\033[K\e[90m@2501 (agent): %s (press Option+TAB to run)\e[0m' "$CURRENT_SUGGESTION"
        printf '\033[1A\r\033[%dC' "$2"
    fi
}

git_info=$(git_prompt_info)
# 2. Replace the command substitution in PS1 with its result
expanded_ps1="${PS1//\$(git_prompt_info)/$git_info}"
# 3. Now, use print -P to expand zsh prompt sequences (like %c, %~, etc.)
prompt_str=$(print -n -P "$expanded_ps1")
# 4. Strip ANSI escape codes if present (remove color codes)
clean_prompt_str=$(echo "$prompt_str" | sed 's/\x1b\[[0-9;]*m//g')
# 5. Measure the length of the cleaned string
prompt_length=$((${#clean_prompt_str} - 1))


_universal_complete() {
    local current_word="$1"
    local cursor_pos="$2"
    local adjusted_cursor_pos=$((prompt_length + cursor_pos))
    
    if [ ${#current_word} -ge 3 ]; then
        # Clear any previous suggestion
        # printf '\r\033[K%s' "$current_word"
        printf '\n\033[K\e[90m%s\e[0m' "..."
        printf '\033[1A\r\033[%dC' "$adjusted_cursor_pos"
        
        _debounced_fetch "$current_word" "$adjusted_cursor_pos"
    fi
}

_execute_suggestion() {
    if [ -n "$CURRENT_SUGGESTION" ]; then
        printf '\r\033[K%s %s' "$prompt_str" "$CURRENT_SUGGESTION"
        printf '\n\033[K\e[90m@2501: %s (press TAB to run)\e[0m\n' "$CURRENT_SUGGESTION" 
        eval "$CURRENT_SUGGESTION"
        CURRENT_SUGGESTION=""
    fi
}

# For bash
if [ -n "$BASH_VERSION" ]; then
    bind '"\e[C": forward-char'
    _bash_complete() {
        echo "EXECUTE B"
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