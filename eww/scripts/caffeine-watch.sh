#!/usr/bin/env bash
# Eww deflisten — report the actual caffeine inhibitor state.

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="${runtime_dir}/eww-caffeine.pid"
last=""

is_active() {
    local pid
    [ -r "$pid_file" ] || return 1
    pid=$(cat "$pid_file" 2>/dev/null)
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

render() {
    if is_active; then
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

render
if command -v inotifywait >/dev/null 2>&1; then
    while changed=$(inotifywait -q -e create,delete,move,close_write --format '%f' "$runtime_dir" 2>/dev/null); do
        case "$changed" in
            "$(basename "$pid_file")") render ;;
        esac
    done
fi

while sleep 5; do
    render
done
