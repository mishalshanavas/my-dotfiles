#!/usr/bin/env bash
# Eww deflisten — report the actual caffeine inhibitor state.

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="${runtime_dir}/eww-caffeine.pid"
last=""

active_pid() {
    local pid comm
    [ -r "$pid_file" ] || return 1
    pid=$(cat "$pid_file" 2>/dev/null)
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    comm=$(cat "/proc/$pid/comm" 2>/dev/null)
    [ "$comm" = "systemd-inhibit" ] || return 1
    printf '%s\n' "$pid"
}

render() {
    if pid=$(active_pid); then
        current="true"
    else
        rm -f "$pid_file"
        current="false"
    fi

    if [ "$current" != "$last" ]; then
        printf '%s\n' "$current"
        last=$current
    fi
}

while true; do
    render

    if pid=$(active_pid); then
        # GNU tail sleeps internally and returns when the inhibitor dies. This
        # catches crashes without adding another once-per-second shell poll.
        if command -v tail >/dev/null 2>&1; then
            tail --pid="$pid" -f /dev/null >/dev/null 2>&1
        else
            while kill -0 "$pid" 2>/dev/null; do sleep 5; done
        fi
    elif command -v inotifywait >/dev/null 2>&1; then
        while changed=$(inotifywait -q -e create,move,close_write --format '%f' "$runtime_dir" 2>/dev/null); do
            [ "$changed" = "$(basename "$pid_file")" ] && break
        done
    else
        sleep 5
    fi
done
