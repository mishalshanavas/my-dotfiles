#!/usr/bin/env bash
# Give Mod+Shift+direction one meaning for both tiled and floating windows.

set -euo pipefail

direction=${1:-}
step=40

focused=$(niri msg --json focused-window 2>/dev/null) || exit 1
window_id=$(jq -r '.id // empty' <<<"$focused")
is_floating=$(jq -r '.is_floating // false' <<<"$focused")

[[ "$window_id" =~ ^[0-9]+$ ]] || exit 1

if [[ "$is_floating" == "true" ]]; then
    case "$direction" in
        left)  exec niri msg action move-floating-window --id "$window_id" --x "-$step" ;;
        right) exec niri msg action move-floating-window --id "$window_id" --x "+$step" ;;
        up)    exec niri msg action move-floating-window --id "$window_id" --y "-$step" ;;
        down)  exec niri msg action move-floating-window --id "$window_id" --y "+$step" ;;
        *) exit 2 ;;
    esac
fi

case "$direction" in
    left)  exec niri msg action move-column-left ;;
    right) exec niri msg action move-column-right ;;
    up)    exec niri msg action move-window-up ;;
    down)  exec niri msg action move-window-down ;;
    *) exit 2 ;;
esac
