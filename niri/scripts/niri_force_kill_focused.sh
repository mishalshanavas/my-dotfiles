#!/usr/bin/env bash
# Force-close the focused application's process when a normal close request fails.

set -u

window_json="$(niri msg --json focused-window 2>/dev/null || true)"
pid="$(jq -r '.pid // empty' <<< "$window_json" 2>/dev/null)"

case "$pid" in
    ''|*[!0-9]*)
        notify-send "Force close unavailable" "The focused window has no process ID."
        exit 1
        ;;
esac

if ! kill -0 "$pid" 2>/dev/null; then
    notify-send "Force close unavailable" "The focused application's process is no longer running."
    exit 1
fi

notify-send "Force closing application" "Sending a termination signal to process $pid."
kill -TERM "$pid"
sleep 0.5
kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"
