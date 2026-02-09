#!/bin/bash

# Caffeine toggle script for waybar
# Prevents screen sleep when active

# Configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-caffeine"
PID_FILE="$CACHE_DIR/caffeine.pid"
START_FILE="$CACHE_DIR/caffeine.start"

mkdir -p "$CACHE_DIR"

get_status() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # Calculate elapsed time
        if [[ -f "$START_FILE" ]]; then
            start_time=$(cat "$START_FILE")
            now=$(date +%s)
            elapsed=$((now - start_time))
            hours=$((elapsed / 3600))
            minutes=$(( (elapsed % 3600) / 60 ))
            seconds=$((elapsed % 60))
            
            if [[ $hours -gt 0 ]]; then
                timer=$(printf "%d:%02d:%02d" $hours $minutes $seconds)
            else
                timer=$(printf "%02d:%02d" $minutes $seconds)
            fi
            echo "{\"text\": \"󰅶 $timer\", \"class\": \"active\", \"tooltip\": \"Caffeine active - click to disable\"}"
        else
            echo "{\"text\": \"󰅶\", \"class\": \"active\", \"tooltip\": \"Caffeine active - click to disable\"}"
        fi
    else
        echo "{\"text\": \"󰛊\", \"class\": \"inactive\", \"tooltip\": \"Caffeine inactive - click to enable\"}"
    fi
}

toggle() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # Disable caffeine
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE" "$START_FILE"
        notify-send "Caffeine" "Screen sleep enabled" -t 2000
    else
        # Enable caffeine - use systemd-inhibit to prevent idle/sleep
        if command -v systemd-inhibit &>/dev/null; then
            systemd-inhibit --what=idle:sleep:handle-lid-switch \
                --who="Waybar Caffeine" \
                --why="User requested screen stay awake" \
                sleep infinity &
            echo $! > "$PID_FILE"
            date +%s > "$START_FILE"
            notify-send "Caffeine" "Screen sleep disabled" -t 2000
        else
            notify-send "Caffeine" "systemd-inhibit not available" -u critical -t 3000
        fi
    fi
}

case "$1" in
    toggle)
        toggle
        ;;
    *)
        get_status
        ;;
esac
