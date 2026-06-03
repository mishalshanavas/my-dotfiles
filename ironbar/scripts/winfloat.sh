#!/bin/sh
wf_status() {
    info=$(niri msg focused-window 2>/dev/null)
    if [ -z "$info" ]; then
        printf '\n'
        return
    fi
    case "$info" in
        *'Is floating: yes'*) printf 'Float\n' ;;
        *)                    printf 'Tiled\n' ;;
    esac
}

wf_status
while true; do
    niri msg event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *Window*|*Workspace*) wf_status ;;
        esac
    done
    wf_status
    sleep 1
done