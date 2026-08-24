#!/usr/bin/env bash
# Resize tiled windows proportionally and floating windows in precise pixel steps.

set -euo pipefail

direction=${1:-}
step=40

focused=$(niri msg --json focused-window 2>/dev/null) || exit 1
window_id=$(jq -r '.id // empty' <<<"$focused")
is_floating=$(jq -r '.is_floating // false' <<<"$focused")

[[ "$window_id" =~ ^[0-9]+$ ]] || exit 1

if [[ "$is_floating" == "true" ]]; then
    case "$direction" in
        left)  exec niri msg action set-window-width --id "$window_id" "-$step" ;;
        right) exec niri msg action set-window-width --id "$window_id" "+$step" ;;
        up)    exec niri msg action set-window-height --id "$window_id" "-$step" ;;
        down)  exec niri msg action set-window-height --id "$window_id" "+$step" ;;
        *) exit 2 ;;
    esac
fi

case "$direction" in
    left)  exec niri msg action set-window-width --id "$window_id" "-10%" ;;
    right) exec niri msg action set-window-width --id "$window_id" "+10%" ;;
    up)    exec niri msg action set-window-height --id "$window_id" "-10%" ;;
    down)  exec niri msg action set-window-height --id "$window_id" "+10%" ;;
    *) exit 2 ;;
esac
