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

_get_shell_type() {
    echo $SHELL
}
