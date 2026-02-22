#!/bin/bash
set -euo pipefail

# Minimal audio menu for waybar with caching

# Configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE_FILE="$CACHE_DIR/audio-devices.cache"
CACHE_DURATION=10  # seconds

mkdir -p "$CACHE_DIR"

# Improved process management
kill_fuzzel() {
    if pgrep -x fuzzel >/dev/null 2>&1; then
        pkill -x fuzzel 2>/dev/null
        sleep 0.05
    fi
}

kill_fuzzel

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'
}

get_mute() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no"
}

# Cache device list using awk for robust parsing
get_device_menu() {
    local cache_valid=false
    
    # Check if cache exists and is recent
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        [[ $cache_age -lt $CACHE_DURATION ]] && cache_valid=true
    fi
    
    if [[ "$cache_valid" != "true" ]]; then
        # Rebuild cache using awk for reliable Name→Description association
        {
            echo "󰓃 Output:"
            pactl list sinks | awk '
                /^\tName: /     { name = $2 }
                /^\tDescription: / { sub(/^\tDescription: /, ""); print "SINK:" name ":" $0 }
            '
            
            echo "──────────────"
            
            echo "󰍬 Input:"
            pactl list sources | awk '
                /^\tName: /     { name = $2 }
                /^\tDescription: / {
                    sub(/^\tDescription: /, "")
                    if (name ~ /\.monitor$/) print "SOURCE:" name ":" $0
                }
            '
        } > "$CACHE_FILE"
    fi
}

show_menu() {
    kill_fuzzel
    
    local VOL MUTED
    VOL=$(get_volume)
    MUTED=$(get_mute)
    
    # Volume bar
    local FILLED=$((VOL / 10))
    local EMPTY=$((10 - FILLED))
    local BAR=""
    for ((i=0; i<FILLED; i++)); do BAR+="█"; done
    for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
    
    # Get cached device list
    get_device_menu
    
    local MENU=""
    local DEFAULT_SINK DEFAULT_SOURCE
    DEFAULT_SINK=$(pactl get-default-sink)
    DEFAULT_SOURCE=$(pactl get-default-source)
    
    while IFS= read -r line; do
        if [[ "$line" == "SINK:"* ]]; then
            IFS=':' read -r _ sink name <<< "$line"
            if [[ "$sink" == "$DEFAULT_SINK" ]]; then
                MENU+="  ● $name\n"
            else
                MENU+="  ○ $name\n"
            fi
        elif [[ "$line" == "SOURCE:"* ]]; then
            IFS=':' read -r _ source name <<< "$line"
            if [[ "$source" == "$DEFAULT_SOURCE" ]]; then
                MENU+="  ● $name\n"
            else
                MENU+="  ○ $name\n"
            fi
        else
            MENU+="$line\n"
        fi
    done < "$CACHE_FILE"

    local CHOSEN
    CHOSEN=$(echo -e "$MENU" | fuzzel --dmenu -p "Audio: ") || true

    [[ -z "${CHOSEN:-}" ]] && exit 0

    case "$CHOSEN" in
        *"○"*)
            name=$(echo "$CHOSEN" | sed 's/.*○ //')
            # Find device from cache
            while IFS= read -r line; do
                if [[ "$line" == "SINK:"* ]]; then
                    IFS=':' read -r _ sink cached_name <<< "$line"
                    [[ "$cached_name" == "$name" ]] && pactl set-default-sink "$sink"
                elif [[ "$line" == "SOURCE:"* ]]; then
                    IFS=':' read -r _ source cached_name <<< "$line"
                    [[ "$cached_name" == "$name" ]] && pactl set-default-source "$source"
                fi
            done < "$CACHE_FILE"
            # Clear cache to refresh on next call
            rm -f "$CACHE_FILE"
            show_menu
            ;;
    esac
}

case "${1:-}" in
    up) swayosd-client --output-volume raise ;;
    down) swayosd-client --output-volume lower ;;
    *) show_menu ;;
esac
