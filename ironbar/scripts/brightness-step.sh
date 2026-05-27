#!/bin/sh
# Adjust brightness in 5% steps with a 5% minimum to avoid blacking out.

if ! command -v brightnessctl >/dev/null 2>&1; then
    exit 0
fi

val=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%')
[ -z "$val" ] && exit 0

step=5
min=5
max=100

case "$1" in
    up)
        new=$((val + step))
        [ "$new" -gt "$max" ] && new=$max
        ;;
    down)
        new=$((val - step))
        [ "$new" -lt "$min" ] && new=$min
        ;;
    *)
        exit 0
        ;;
esac

brightnessctl set "${new}%" >/dev/null 2>&1 || true
