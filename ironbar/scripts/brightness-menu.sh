#!/bin/sh
if ! command -v brightnessctl >/dev/null 2>&1; then
    exit 0
fi

val=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%')
[ -z "$val" ] && exit 0

for preset in 10 25 50 75 100; do
    if [ "$val" -lt "$preset" ]; then
        brightnessctl set "${preset}%" >/dev/null 2>&1 || true
        exit 0
    fi
done

brightnessctl set "10%" >/dev/null 2>&1 || true
