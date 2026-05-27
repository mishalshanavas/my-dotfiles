#!/bin/sh
# Cycle the default audio sink to the next available device.

if ! command -v wpctl >/dev/null 2>&1; then
    exit 0
fi

sinks=$(wpctl status 2>/dev/null | awk '
    $1 == "Sinks:" { in_section = 1; next }
    $1 == "Sources:" { in_section = 0 }
    in_section {
        if (match($0, /[0-9]+\./)) {
            id = substr($0, RSTART, RLENGTH)
            sub(/\./, "", id)
            print id
        }
    }
')

[ -z "$sinks" ] && exit 0

default_id=$(wpctl get-default @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $1}')
if [ -z "$default_id" ]; then
    default_id=$(printf "%s\n" "$sinks" | head -n 1)
fi

next=""
found=0
for id in $sinks; do
    if [ "$found" = "1" ]; then
        next="$id"
        break
    fi
    if [ "$id" = "$default_id" ]; then
        found=1
    fi
done

if [ -z "$next" ]; then
    next=$(printf "%s\n" "$sinks" | head -n 1)
fi

[ -n "$next" ] && wpctl set-default "$next" 2>/dev/null || true
