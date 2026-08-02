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

    # ── Easter egg: boost counter inflates by +3 per tap ──
    boost_file="/tmp/battery-boost-$(id -u)"
    if [ -f "$boost_file" ]; then
        tap_count=$(cat "$boost_file" 2>/dev/null)
        tap_count=$((tap_count))
        [ "$tap_count" -gt 0 ] 2>/dev/null && pct=$((pct + tap_count * 3))
        [ "$pct" -gt 100 ] && pct=100
    fi

    case "$state_raw" in
        charging|fully-charged|pending-charge) status="charging" ;;
        *) status="discharging" ;;
    esac

    if [ "$status" = "charging" ]; then
        icon=$'\ue1a3'
    elif [ -n "$pct" ] && [ "$pct" -ge 90 ]; then icon=$'\ue1a5'
    elif [ -n "$pct" ] && [ "$pct" -ge 70 ]; then icon=$'\uf0a1'
    elif [ -n "$pct" ] && [ "$pct" -ge 50 ]; then icon=$'\uf09f'
    elif [ -n "$pct" ] && [ "$pct" -ge 20 ]; then icon=$'\uf09e'
    else icon=$'\uf09c'
    fi

    if [ -n "$pct" ]; then
        printf '%s %s%%\n' "$icon" "$pct"
    else
        printf '%s --%%\n' "$icon"
    fi
}

BAT_DEV=$(find_battery)
while [ -z "$BAT_DEV" ]; do
    printf '%s N/A\n' $'\uf09c'
    sleep 30
    BAT_DEV=$(find_battery)
done

render
if command -v upower >/dev/null 2>&1; then
    upower --monitor 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *"$BAT_DEV"*) render ;;
        esac
    done
fi

while sleep 30; do
    render
done
