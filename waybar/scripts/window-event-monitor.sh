#!/bin/bash
set -uo pipefail

# Background monitor: watches niri event stream for window changes
# and instantly signals waybar to refresh the window-state module.
#
# Add to Niri startup: spawn-at-startup "~/.config/waybar/scripts/window-event-monitor.sh"

# Kill any existing instance
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/window-event-monitor.pid"
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

# Listen to niri event stream and signal waybar on relevant changes
niri msg event-stream 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        "Windows changed:"*|"Workspaces changed:"*|"Window focus changed:"*|"Workspace "*": active window changed to"*)
            pkill -RTMIN+9 waybar 2>/dev/null || true
            ;;
    esac
done
