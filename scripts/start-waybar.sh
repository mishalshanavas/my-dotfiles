#!/bin/bash

# Waybar startup script with system readiness check
# Ensures waybar starts only after essential services are ready

set -euo pipefail

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
LOG_FILE="$LOG_DIR/waybar.log"
WAYBAR_CONFIG="/home/mishal/.config/waybar/config.jsonc"
WAYBAR_STYLE="/home/mishal/.config/waybar/style.css"

mkdir -p "$LOG_DIR"

# Wait for niri to be fully ready
sleep 0.3

# If waybar is already running, just reload it.
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -x -USR2 waybar 2>/dev/null || true
    exit 0
fi

LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/start-waybar.lock"

# Prevent concurrent starts (e.g., resume hooks firing repeatedly)
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

# Race check after acquiring the lock
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -x -USR2 waybar 2>/dev/null || true
    exit 0
fi

# Wait for essential services to be available
for i in {1..10}; do
    # Check if PulseAudio/PipeWire is ready (for audio module)
    if command -v wpctl >/dev/null 2>&1 && wpctl get-volume @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1; then
        # Check if NetworkManager is ready (for network module) 
        if nmcli dev status >/dev/null 2>&1; then
            # Check if brightness control is ready
            if brightnessctl -l >/dev/null 2>&1; then
                break
            fi
        fi
    fi
    sleep 0.1
done

# Event-driven updates (safe if already running)
"/home/mishal/.config/waybar/scripts/window-event-monitor.sh" &
"/home/mishal/.config/waybar/scripts/power-monitor.sh" &

# Start waybar (log output for debugging)
echo "[$(date -Is)] starting waybar" >> "$LOG_FILE"
exec waybar -c "$WAYBAR_CONFIG" -s "$WAYBAR_STYLE" >> "$LOG_FILE" 2>&1