#!/bin/sh
battery_path() {
    for dev in /sys/class/power_supply/*; do
        [ -f "$dev/type" ] || continue
        if [ "$(cat "$dev/type" 2>/dev/null)" = "Battery" ]; then
            printf '%s\n' "$dev"
            return 0
        fi
    done
    return 1
}

BAT_PATH=$(battery_path)
[ -z "$BAT_PATH" ] && exit 0

last_level=101

maybe_notify() {
    pct=$1
    status=$2

    if [ "$status" != "Discharging" ]; then
        last_level=101
        return
    fi

    if [ "$pct" -le 10 ] && [ "$last_level" -gt 10 ]; then
        notify-send -u critical "Battery critical" "${pct}% remaining" 2>/dev/null || true
    elif [ "$pct" -le 20 ] && [ "$last_level" -gt 20 ]; then
        notify-send -u normal "Battery low" "${pct}% remaining" 2>/dev/null || true
    fi

    last_level=$pct
}

bat_status() {
    pct=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    status=$(cat "$BAT_PATH/status" 2>/dev/null)
    [ -z "$pct" ] && return

    maybe_notify "$pct" "$status"

    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        icon=""
    elif [ "$pct" -ge 90 ]; then icon=""
    elif [ "$pct" -ge 70 ]; then icon=""
    elif [ "$pct" -ge 50 ]; then icon=""
    elif [ "$pct" -ge 20 ]; then icon=""
    else icon=""
    fi
    echo "${icon}  ${pct}%"
}

bat_status
udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null | while read -r _; do
    bat_status
done
