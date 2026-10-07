#!/usr/bin/env bash

set -u

runtime_dir=${XDG_RUNTIME_DIR:-}
if [ -z "$runtime_dir" ] || [ ! -d "$runtime_dir" ]; then
    printf 'power-toggle: XDG_RUNTIME_DIR is not set to a directory\n' >&2
    exit 1
fi

pid_file="$runtime_dir/power-block.pid"
lock_file="$runtime_dir/power-block.lock"
exec 9>"$lock_file"
flock 9

inhibitor_running() {
    local pid
    [ -r "$pid_file" ] || return 1
    pid=$(<"$pid_file")
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -Fq 'handle-power-key'
}

start_inhibitor() {
    systemd-inhibit --what=handle-power-key --who=eww --why='power key disabled' --mode=block sleep infinity \
        </dev/null >/dev/null 2>&1 9>&- &
    printf '%s\n' "$!" >"$pid_file"
    sleep 0.1
    if ! inhibitor_running; then
        rm -f "$pid_file"
        printf 'power-toggle: failed to start systemd-inhibit\n' >&2
        return 1
    fi
}

case "${1:-}" in
    status)
        if inhibitor_running; then
            printf 'off\n'
        else
            rm -f "$pid_file"
            printf 'on\n'
        fi
        ;;
    toggle)
        if inhibitor_running; then
            pid=$(<"$pid_file")
            kill "$pid" 2>/dev/null || true
            rm -f "$pid_file"
            state=on
        else
            rm -f "$pid_file"
            start_inhibitor || exit 1
            state=off
        fi
        # Eww's existing five-second poll refreshes the icon. Calling eww
        # update from this click handler can block until the handler times out.
        notification_state=off
        [ "$state" = off ] && notification_state=on
        notify-send "Anti Jual Mode" "$notification_state" >/dev/null 2>&1 || true
        printf '%s\n' "$state"
        ;;
    *)
        printf 'Usage: power-toggle {status|toggle}\n' >&2
        exit 2
        ;;
esac
