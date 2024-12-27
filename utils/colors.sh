#!/bin/bash
# Colors utils

set -a

# Color tokens for dark theme
_set_dark_theme() {
    GRAY_240='240m' # This is the darkest gray for secondary stuffs
    GRAY_90='90m' # This is the main shade of gray
    GRAY_80='80m'
    GRAY_70='70m'
    GRAY_60='60m'
    GRAY_50='50m'
    GRAY_40='40m'
    GRAY_30='30m'
    GRAY_20='20m'

    WHITE_15='15m'
    WHITE_10='10m'
    WHITE_5='5m'
    WHITE_0='0m'

    RESET='0m'
    GREEN='190m' # Used for selected suggestion
    GREEN_ALT='192m' # Used for agent prompt

    SUGGESTION_COLORS=(246 244 242 240)  # Dark to lighter grays
}

# Color tokens for light theme
_set_light_theme() {
    GRAY_240='240m' # This shade work on both dark and light theme
    GRAY_90='210m' # Lighter gray for kught theme
    GRAY_80='80m'
    GRAY_70='70m'
    GRAY_60='60m'
    GRAY_50='50m'
    GRAY_40='40m'
    GRAY_30='30m'
    GRAY_20='20m'

    WHITE_15='15m'
    WHITE_10='10m'
    WHITE_5='5m' # Swapped 5m and 0m for light theme for better contrast
    WHITE_0='0m' # Swapped 5m and 0m for light theme for better contrast

    RESET='0m'
    GREEN='22m'      # Darker green for selected suggestion
    GREEN_ALT='28m' # Darker green for agent prompt

    SUGGESTION_COLORS=(238 240 242 244)  # Same as light, but starting darker
}

set_theme() {
    # Detect terminal background color (light/dark)
    if [ "$COLORFGBG" ]; then
        bg_color=${COLORFGBG##*;}
        # echo "Debug: COLORFGBG=$COLORFGBG, extracted bg_color=$bg_color"
        
        # For dark backgrounds, bg_color is typically 0
        # For light backgrounds, bg_color is typically 15
        if [ "$bg_color" -eq 0 ]; then
            # echo "Detected dark terminal theme"
            _set_dark_theme
        else
            # echo "Detected light terminal theme"
            _set_light_theme
        fi
    else
        # echo "Could not detect terminal theme, defaulting to dark theme"
        _set_dark_theme
    fi
}

set_theme
