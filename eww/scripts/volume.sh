#!/usr/bin/env bash
# Eww deflisten — volume status via pactl
# Output: "icon percentage%"

get_default_sink() {
    pactl get-default-sink 2>/dev/null
}

render() {
    local sink vol mute icon
    sink=$(get_default_sink)
    [ -z "$sink" ] && { printf ' --%%\n'; return; }

    vol=$(pactl get-sink-volume "$sink" 2>/dev/null | awk 'NR==1{print $5}' | tr -d '%')
    mute=$(pactl get-sink-mute "$sink" 2>/dev/null | awk '{print $2}')

    if [ "$mute" = "yes" ]; then
        printf ' Muted\n'
    elif [ -z "$vol" ]; then
        printf ' --%%\n'
    elif [ "$vol" -ge 70 ]; then
        printf ' %s%%\n' "$vol"
    elif [ "$vol" -ge 30 ]; then
        printf ' %s%%\n' "$vol"
    else
        printf ' %s%%\n' "$vol"
    fi
}

render
# Subscribe to pactl events
pactl subscribe 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"change"*"sink"*|*"change"*"server"*) render ;;
    esac
done
