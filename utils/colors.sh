#!/bin/bash
# Colors utils

get_terminal_bg_color() {
    echo "TERMINAL COLOR CHEEEECK"
    local oldstty=$(stty -g)

    # What to query?
    # 11: text background
    Ps=${1:-11}

    stty raw -echo min 0 time 0
    printf "\033]%s;?\033\\" "$Ps"
    # xterm needs the sleep (or "time 1", but that is 1/10th second).
    sleep 0.01
    IFS= read -r -t 1 answer
    result=${answer#*;}
    stty "$oldstty"
    # Remove escape at the end.
    echo "$result" | sed 's/[^rgb:0-9a-f/]\+$//'
}