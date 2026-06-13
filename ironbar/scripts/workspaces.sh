#!/usr/bin/env bash
render() {
    first=1
    niri msg workspaces 2>/dev/null | grep -E '^[[:space:]]' | while IFS= read -r line; do
        [ "$first" = "1" ] && first=0 || printf ' '
        case "$line" in
            *'*'*) printf '●' ;;
            *)     printf '·' ;;
        esac
    done
    printf '\n'
}

render
while true; do
    niri msg event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *Workspace*|*Window*) render ;;
        esac
    done
    render
    sleep 1
done