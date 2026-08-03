#!/usr/bin/env bash
# Toggle a real idle/sleep inhibitor and persist its process ID for the bar.

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="${runtime_dir}/eww-caffeine.pid"

if [ -r "$pid_file" ]; then
    pid=$(cat "$pid_file" 2>/dev/null)
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        rm -f "$pid_file"
        exit 0
    fi
    rm -f "$pid_file"
fi

if ! command -v systemd-inhibit >/dev/null 2>&1; then
    notify-send "Caffeine" "systemd-inhibit is not installed" 2>/dev/null || true
    exit 1
fi

systemd-inhibit \
    --what=idle:sleep \
    --who="Eww caffeine" \
    --why="Caffeine mode is enabled" \
    --mode=block \
    sleep infinity >/dev/null 2>&1 &
pid=$!

if kill -0 "$pid" 2>/dev/null; then
    printf '%s\n' "$pid" > "$pid_file"
else
    notify-send "Caffeine" "Failed to inhibit sleep" 2>/dev/null || true
    exit 1
fi
