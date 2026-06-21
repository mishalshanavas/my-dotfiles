#!/bin/sh
# Eww deflisten — caffeine status via inotify (instant)

FILE="/tmp/caffeine-${UID}"

render() {
    if [ -f "$FILE" ]; then
        printf '\n'
    else
        printf '\n'
    fi
}

render
while inotifywait -q -e create,delete /tmp 2>/dev/null; do
    render
done
