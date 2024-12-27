#!/bin/bash
# System information utilities

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

_get_history() {
    history | tail -n 100 | tr '\n' ',' | sed 's/,$//'
}

_get_top_100_commands(){
    history \
        | awk '
            # 1) Remove the line number from "history" output
            # 2) Trim leading spaces
            # 3) Count occurrences of each exact command line
            {
                $1 = ""
                sub(/^ +/, "")
                commands[$0]++
            }

            # 4) Print "count command" for each unique line
            END {
                for (cmd in commands) {
                print commands[cmd], cmd
                }
            }
            ' \
        | sort -nr              \
        | head -n 100           \
        | awk '
            # In this second awk:
            #   - $1 = usage count
            #   - $2.. = the command itself
            #   - Remove $1 so only the command remains
            #   - Build a single line of commands separated by ", "
            {
                $1 = ""
                sub(/^ +/, "")
                if (NR == 1) {
                # First command
                printf "%s", $0
                } else {
                # Subsequent commands
                printf ", %s", $0
                }
            }

            END {
                # End with a newline
                printf "\n"
            }
            '
}

_get_shell_type() {
    echo $SHELL
}
