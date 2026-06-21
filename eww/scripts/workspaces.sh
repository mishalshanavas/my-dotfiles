#!/usr/bin/env bash
# Eww deflisten — niri workspaces
# Output: workspace indicator string, one line per update

render() {
    local output=""
    local first=1
    niri msg workspaces 2>/dev/null | grep -E '^[[:space:]]' | while IFS= read -r line; do
        [ "$first" = "1" ] && first=0 || printf ' '
        case "$line" in
            *'*'*) printf '●' ;;
            *)     printf '○' ;;
        esac
    done
    printf '\n'
}

render
niri msg event-stream 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *Workspace*|*Window*) render ;;
    esac
done
