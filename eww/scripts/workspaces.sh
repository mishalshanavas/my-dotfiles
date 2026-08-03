#!/usr/bin/env bash
# Eww deflisten — niri workspaces
# Synchronize nine individually clickable workspace indicators.
# The focused workspace is filled; all others are outlined.

render() {
    local data
    local -a updates
    data=$(niri msg --json workspaces 2>/dev/null) || data='[]'

    mapfile -t updates < <(printf '%s\n' "$data" | jq -r '
        range(1; 10) as $idx
        | ([.[] | select(.idx == $idx)] | length > 0) as $visible
        | ([.[] | select(.idx == $idx and .is_focused)] | length > 0) as $focused
        | "workspace_\($idx)=\(if $focused then "●" else "○" end)",
          "workspace_visible_\($idx)=\(if $visible then "true" else "false" end)"
    ')

    eww update "${updates[@]}" >/dev/null 2>&1 || true

    printf '\n'
}

render
sleep 0.5
render
while true; do
    niri msg event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *Workspace*|*Window*) render ;;
        esac
    done
    sleep 1
done
