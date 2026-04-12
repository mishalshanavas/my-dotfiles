#!/bin/bash
set -uo pipefail

# Background power supply monitor for waybar
# Watches for charger plug/unplug events and instantly signals waybar
# to refresh the battery module (RTMIN+10).
#
# Usage: Run this in your Niri/compositor startup config:
#   exec ~/.config/waybar/scripts/power-monitor.sh &
#
# It uses upower --monitor to detect power changes with zero polling.

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-power-monitor.pid"
if [[ -f "$PIDFILE" ]]; then
    old_pid=$(cat "$PIDFILE")
    if kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null
        sleep 0.1
    fi
fi
echo $$ > "$PIDFILE"

cleanup() { rm -f "$PIDFILE"; }
trap cleanup EXIT

read_status() {
    cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1
}

read_capacity() {
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1
}

LAST_STATUS=$(read_status)
LAST_CAPACITY=$(read_capacity)

# Monitor power supply changes via upower (event-driven)
upower --monitor 2>/dev/null | while read -r line; do
    # React to battery/line-power change events
    if [[ "$line" == *"battery"* ]] || [[ "$line" == *"line-power"* ]] || [[ "$line" == *"power_supply"* ]]; then
        # Small debounce — upower can fire multiple events per change
        sleep 0.3

        CURRENT_STATUS=$(read_status)
        CURRENT_CAPACITY=$(read_capacity)

        if [[ "$CURRENT_STATUS" != "$LAST_STATUS" ]] || [[ "$CURRENT_CAPACITY" != "$LAST_CAPACITY" ]]; then
            LAST_STATUS="$CURRENT_STATUS"
            LAST_CAPACITY="$CURRENT_CAPACITY"
            pkill -RTMIN+10 waybar 2>/dev/null || true
        fi
    fi
done
