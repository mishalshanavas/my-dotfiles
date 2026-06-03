#!/bin/sh
# Cycle the default audio sink to the next available device.

command -v wpctl >/dev/null 2>&1 || exit 0

# Collect all sink IDs in order
sinks=$(wpctl status 2>/dev/null | awk '
    /^[[:space:]]*Sinks:/   { in_sinks = 1; next }
    /^[[:space:]]*Sources:/ { in_sinks = 0 }
    in_sinks && /[0-9]+\./ {
        match($0, /[0-9]+\./)
        id = substr($0, RSTART, RLENGTH - 1)
        print id
    }
')

[ -z "$sinks" ] && exit 0

# Find the currently default sink (marked with *)
default_id=$(wpctl status 2>/dev/null | awk '
    /^[[:space:]]*Sinks:/   { in_sinks = 1; next }
    /^[[:space:]]*Sources:/ { in_sinks = 0 }
    in_sinks && /\*/ && /[0-9]+\./ {
        match($0, /[0-9]+\./)
        print substr($0, RSTART, RLENGTH - 1)
        exit
    }
')

[ -z "$default_id" ] && default_id=$(printf '%s\n' "$sinks" | head -n 1)

# Pick the next sink, wrapping around
next=""
found=0
for id in $sinks; do
    if [ "$found" = "1" ]; then
        next="$id"
        break
    fi
    [ "$id" = "$default_id" ] && found=1
done

[ -z "$next" ] && next=$(printf '%s\n' "$sinks" | head -n 1)
[ -n "$next" ] && wpctl set-default "$next" 2>/dev/null