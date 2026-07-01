#!/usr/bin/env bash

set -euo pipefail

caffeine_file="${XDG_RUNTIME_DIR:-/tmp}/caffeine-$(id -u)"
lock_cmd="/home/mishal/.config/swaylock/lock.sh"

case "${1:-run}" in
    maybe-lock)
        [[ -e "$caffeine_file" ]] || exec "$lock_cmd"
        exit 0
        ;;
    maybe-power-off-monitors)
        [[ -e "$caffeine_file" ]] || exec niri msg action power-off-monitors
        exit 0
        ;;
    lock-before-sleep)
        "$lock_cmd" && exec niri msg action power-off-monitors
        exit 0
        ;;
    run)
        ;;
    *)
        printf 'usage: %s [run|maybe-lock|maybe-power-off-monitors|lock-before-sleep]\n' "$0" >&2
        exit 2
        ;;
esac

exec swayidle -w \
    timeout 300 "$0 maybe-lock" \
    timeout 600 "$0 maybe-power-off-monitors" \
    resume 'niri msg action power-on-monitors' \
    before-sleep "$0 lock-before-sleep" \
    lock "$lock_cmd"
