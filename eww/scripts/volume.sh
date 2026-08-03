#!/usr/bin/env bash
# Eww deflisten — volume status via pactl
# Output: "icon percentage%"

get_default_sink() {
    pactl get-default-sink 2>/dev/null
}

render() {
    local sink vol mute icon
    sink=$(get_default_sink)
    [ -z "$sink" ] && { printf '<span font_family="Material Symbols Rounded">%s</span> --%%\n' $'\ue04f'; return; }

    vol=$(pactl get-sink-volume "$sink" 2>/dev/null | awk 'NR==1{print $5}' | tr -d '%')
    mute=$(pactl get-sink-mute "$sink" 2>/dev/null | awk '{print $2}')

    if [ "$mute" = "yes" ]; then
        printf '<span font_family="Material Symbols Rounded">%s</span> Muted\n' $'\ue04f'
    elif ! [[ "$vol" =~ ^[0-9]+$ ]]; then
        printf '<span font_family="Material Symbols Rounded">%s</span> --%%\n' $'\ue050'
    elif [ "$vol" -ge 70 ]; then
        printf '<span font_family="Material Symbols Rounded">%s</span> %s%%\n' $'\ue050' "$vol"
    elif [ "$vol" -ge 30 ]; then
        printf '<span font_family="Material Symbols Rounded">%s</span> %s%%\n' $'\ue04d' "$vol"
    else
        printf '<span font_family="Material Symbols Rounded">%s</span> %s%%\n' $'\ue04d' "$vol"
    fi
}

render
# Subscribe to pactl events. If PulseAudio/PipeWire restarts and the
# subscription ends, keep the listener alive with a low-frequency poll.
if command -v pactl >/dev/null 2>&1; then
    pactl subscribe 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *"change"*"sink"*|*"change"*"server"*) render ;;
        esac
    done
fi

while sleep 5; do
    render
done
