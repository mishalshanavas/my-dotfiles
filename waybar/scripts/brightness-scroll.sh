#!/bin/bash

# Brightness scroll control with minimum limit and debounce
# Configuration
TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}"
MIN=10
LOCK_FILE="$TMP_DIR/brightness-scroll.lock"
DEBOUNCE_MS=100

# Debounce: exit if last scroll was too recent
if [[ -f "$LOCK_FILE" ]]; then
    LAST=$(cat "$LOCK_FILE")
    NOW=$(date +%s%3N)
    DIFF=$((NOW - LAST))
    if [[ $DIFF -lt $DEBOUNCE_MS ]]; then
        exit 0
    fi
fi
echo $(date +%s%3N) > "$LOCK_FILE"

get_brightness() {
    brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}'
}

case "$1" in
    up)
        swayosd-client --brightness raise
        ;;
    down)
        CURRENT=$(get_brightness)
        if [[ $CURRENT -gt $MIN ]]; then
            swayosd-client --brightness lower
            # Check if it went below minimum and correct
            NEW=$(get_brightness)
            if [[ $NEW -lt $MIN ]]; then
                brightnessctl set ${MIN}% >/dev/null
            fi
        fi
        ;;
esac

pkill -RTMIN+8 waybar
