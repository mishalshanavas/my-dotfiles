#!/bin/sh
# Eww deflisten — caffeine status via inotify (instant)

uid=$(id -u)
DIR="${XDG_RUNTIME_DIR:-/tmp}"
FILE="${DIR}/caffeine-${uid}"
last=""

render() {
    if [ -f "$FILE" ]; then
        current=''
    else
        current=''
    fi

    if [ "$current" != "$last" ]; then
        printf '%s\n' "$current"
        last=$current
    fi
}

render
if command -v inotifywait >/dev/null 2>&1; then
    while changed=$(inotifywait -q -e create,delete,move,close_write --format '%f' "$DIR" 2>/dev/null); do
        case "$changed" in
            "$(basename "$FILE")") render ;;
        esac
    done
fi

while sleep 5; do
    render
done
