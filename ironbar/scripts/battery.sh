#!/bin/sh
battery_device() {
    command -v upower >/dev/null 2>&1 || return 1
    upower -e 2>/dev/null | awk '/battery/ {print; exit}'
}

is_int() {
    case $1 in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

read_info() {
    upower -i "$BAT_DEV" 2>/dev/null | awk -F': *' '
        /^[[:space:]]*state:/      { state = $2 }
        /^[[:space:]]*percentage:/ { pct = $2; gsub(/%/, "", pct); gsub(/\.[0-9]*/, "", pct) }
        END {
            if (state == "") state = "unknown"
            print state "|" pct
        }
    '
}

normalize_state() {
    case "$1" in
        charging|fully-charged|pending-charge) printf 'Charging\n' ;;
        discharging|pending-discharge)         printf 'Discharging\n' ;;
        *)                                     printf 'Unknown\n' ;;
    esac
}

render() {
    info=$(read_info)
    state_raw=${info%%|*}
    pct=${info#*|}
    status=$(normalize_state "$state_raw")

    # Notify on low battery — use a state file to avoid re-notifying
    if [ "$status" = "Discharging" ] && is_int "$pct"; then
        for threshold in 10 20; do
            flag="/tmp/.bat_notified_${threshold}"
            if [ "$pct" -le "$threshold" ] && [ ! -f "$flag" ]; then
                touch "$flag"
                if [ "$threshold" -eq 10 ]; then
                    notify-send -u critical "Battery critical" "${pct}% remaining" 2>/dev/null || true
                else
                    notify-send -u normal "Battery low" "${pct}% remaining" 2>/dev/null || true
                fi
            elif [ "$pct" -gt "$threshold" ] && [ -f "$flag" ]; then
                rm -f "$flag"
            fi
        done
    fi

    if [ "$status" = "Charging" ]; then
        icon=""
    elif is_int "$pct" && [ "$pct" -ge 90 ]; then icon=""
    elif is_int "$pct" && [ "$pct" -ge 70 ]; then icon=""
    elif is_int "$pct" && [ "$pct" -ge 50 ]; then icon=""
    elif is_int "$pct" && [ "$pct" -ge 20 ]; then icon=""
    else icon=""
    fi

    if is_int "$pct"; then
        printf '%s  %s%%\n' "$icon" "$pct"
    else
        printf '%s  --%%\n' "$icon"
    fi
}

BAT_DEV=$(battery_device)
[ -z "$BAT_DEV" ] && exit 0

render
upower --monitor 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"$BAT_DEV"*) render ;;
    esac
done