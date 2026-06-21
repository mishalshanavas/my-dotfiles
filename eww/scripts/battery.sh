#!/usr/bin/env bash
# Eww deflisten — battery via upower
# Output: "icon percentage%"

find_battery() {
    upower -e 2>/dev/null | awk '/battery/ {print; exit}'
}

render() {
    local info state_raw pct status icon

    info=$(upower -i "$BAT_DEV" 2>/dev/null | awk -F': *' '
        /^[[:space:]]*state:/      { state = $2 }
        /^[[:space:]]*percentage:/ { pct = $2; gsub(/%/, "", pct); gsub(/\.[0-9]*/, "", pct) }
        END { if (state == "") state = "unknown"; print state "|" pct }
    ')

    state_raw=${info%%|*}
    pct=${info#*|}

    case "$state_raw" in
        charging|fully-charged|pending-charge) status="charging" ;;
        *) status="discharging" ;;
    esac

    if [ "$status" = "charging" ]; then
        icon=''
    elif [ -n "$pct" ] && [ "$pct" -ge 90 ]; then icon=''
    elif [ -n "$pct" ] && [ "$pct" -ge 70 ]; then icon=''
    elif [ -n "$pct" ] && [ "$pct" -ge 50 ]; then icon=''
    elif [ -n "$pct" ] && [ "$pct" -ge 20 ]; then icon=''
    else icon=''
    fi

    if [ -n "$pct" ]; then
        printf '%s %s%%\n' "$icon" "$pct"
    else
        printf '%s --%%\n' "$icon"
    fi
}

BAT_DEV=$(find_battery)
[ -z "$BAT_DEV" ] && { printf ' N/A\n'; sleep infinity; }

render
upower --monitor 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"$BAT_DEV"*) render ;;
    esac
done
