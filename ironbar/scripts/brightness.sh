#!/bin/sh
if ! command -v brightnessctl >/dev/null 2>&1; then
    echo "  N/A"
    exit 0
fi

val=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')

if [ -z "$val" ]; then
    echo "  N/A"
    exit 0
fi

if [ "$val" -ge 75 ]; then
    icon=""
elif [ "$val" -ge 40 ]; then
    icon=""
elif [ "$val" -ge 10 ]; then
    icon=""
else
    icon=""
fi
echo "${icon}  ${val}%"
