#!/bin/bash
set -uo pipefail

# Background power supply monitor for waybar
# Watches for charger plug/unplug events and instantly signals waybar
# to refresh the battery module (RTMIN+10).
#
# Usage: Run this in your Niri/compositor startup config:
#   exec ~/.config/waybar/scripts/power-monitor.sh &
#
# It uses upower --monitor to detect AC adapter changes with zero polling.

LAST_STATUS=""

# Read initial status
LAST_STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)

# Monitor power supply changes via upower (event-driven, no polling)
upower --monitor 2>/dev/null | while read -r line; do
    # Only react to battery/line-power change events
    if [[ "$line" == *"battery"* ]] || [[ "$line" == *"line-power"* ]] || [[ "$line" == *"power_supply"* ]]; then
        # Small debounce — upower can fire multiple events per plug/unplug
        sleep 0.3
        
        CURRENT_STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
        
        # Only signal waybar if the charging status actually changed
        if [[ "$CURRENT_STATUS" != "$LAST_STATUS" ]]; then
            LAST_STATUS="$CURRENT_STATUS"
            pkill -RTMIN+10 waybar 2>/dev/null || true
        fi
    fi
done
