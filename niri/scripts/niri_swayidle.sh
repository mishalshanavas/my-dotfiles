#!/usr/bin/env bash

set -euo pipefail

caffeine_pid_file="${XDG_RUNTIME_DIR:-/tmp}/eww-caffeine.pid"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
lock_cmd="$config_dir/swaylock/lock.sh"

caffeine_active() {
    local pid
    [[ -r "$caffeine_pid_file" ]] || return 1
    IFS= read -r pid < "$caffeine_pid_file" || return 1
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

case "${1:-run}" in
    maybe-lock)
        caffeine_active || exec "$lock_cmd"
        exit 0
        ;;
    maybe-power-off-monitors)
        caffeine_active || exec niri msg action power-off-monitors
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
