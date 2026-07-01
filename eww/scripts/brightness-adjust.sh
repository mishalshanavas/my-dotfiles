#!/usr/bin/env bash
# Adjust backlight brightness for the Eww bar. Never goes below 10%.

direction=${1:-}
min_pct=10
step_pct=10

if ! command -v brightnessctl >/dev/null 2>&1; then
    notify-send "Brightness" "brightnessctl not found" 2>/dev/null || true
    exit 1
fi

current=$(brightnessctl -c backlight get 2>/dev/null) || exit 1
max=$(brightnessctl -c backlight max 2>/dev/null) || exit 1

case "$current:$max" in
    *[!0-9:]*|:|*:|:*) exit 1 ;;
esac

min=$(( (max * min_pct + 99) / 100 ))
step=$(( (max * step_pct + 99) / 100 ))

case "$direction" in
    up)
        target=$(( current + step ))
        [ "$target" -gt "$max" ] && target=$max
        ;;
    down)
        target=$(( current - step ))
        [ "$target" -lt "$min" ] && target=$min
        ;;
    *)
        exit 0
        ;;
esac

brightnessctl -c backlight set "$target" >/dev/null 2>&1
