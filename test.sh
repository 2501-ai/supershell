#!/bin/bash

_echo() {
    echo "pressed alt-enter"
    zle .accept-line
}

zle -N _echo