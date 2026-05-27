#!/bin/sh
render() {
    first=1
    niri msg workspaces 2>/dev/null | grep '^\s' | while IFS= read -r line; do
        [ "$first" = "1" ] && first=0 || printf ' '
        if echo "$line" | grep -q '^\s\*'; then
            printf '⬤'
        else
            printf '◯'
        fi
    done
    printf '\n'
}

render
while true; do
    niri msg event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *Workspace*|*Window*)
                render ;;
        esac
    done
    sleep 1
done
