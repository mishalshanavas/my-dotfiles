#!/usr/bin/env bash
# Eww deflisten — niri workspaces
# Output: round workspace indicator, one line per update.
# The focused workspace is filled; all others are outlined.

render() {
    niri msg --json workspaces 2>/dev/null | jq -r '
        sort_by(.idx)
        | map(if .is_focused then "●" else "○" end)
        | join("\u2009")
      ' || printf '?\n'
}

render
while true; do
    niri msg event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *Workspace*|*Window*) render ;;
        esac
    done
    sleep 1
done
