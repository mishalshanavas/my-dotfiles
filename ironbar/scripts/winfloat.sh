#!/bin/sh
wf_status() {
    info=$(niri msg focused-window 2>/dev/null)
    if [ -z "$info" ]; then echo ""; return; fi
    if echo "$info" | grep -q "Is floating: yes"; then
        echo "Float"
    else
        echo "Tiled"
    fi
}
wf_status
while true; do
    niri msg event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *Window*|*Workspace*) wf_status ;;
        esac
    done
    sleep 1
done
