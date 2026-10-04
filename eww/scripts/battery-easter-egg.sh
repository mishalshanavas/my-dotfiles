#!/usr/bin/env bash

set -u

runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
token_file="$runtime_dir/eww-battery-override.token"
lock_file="$runtime_dir/eww-battery-override.lock"

case "${1:-}" in
    __restore)
        token=${2:-}
        sleep 5
        exec 9>"$lock_file"
        flock 9
        if [ -r "$token_file" ] && [ "$(<"$token_file")" = "$token" ]; then
            rm -f "$token_file"
            eww update battery_display_override="" >/dev/null 2>&1 || true
        fi
        exit 0
        ;;
    "")
        ;;
    *)
        exit 2
        ;;
esac

exec 9>"$lock_file"
flock 9
current=$(eww get battery_display_override 2>/dev/null || true)
[ -n "$current" ] || current=$(eww get battery 2>/dev/null || true)
percentage=$(printf '%s\n' "$current" | grep -oE '[0-9]+%' | tail -n 1 | tr -d '%')
[[ "$percentage" =~ ^[0-9]+$ ]] || exit 0

prefix=$(printf '%s\n' "$current" | sed -E 's/[0-9]+%.*$//')
updated_value="${prefix}$((percentage + 5))%"
token="$(date +%s%3N)-$$"
printf '%s\n' "$token" >"$token_file"
eww update battery_display_override="$updated_value" >/dev/null 2>&1 || true
"$0" __restore "$token" </dev/null >/dev/null 2>&1 9>&- &
