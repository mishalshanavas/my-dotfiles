#!/bin/bash
set -uo pipefail

# Waybar script to show floating/tiled window state indicator

get_window_state() {
    local window_info
    window_info=$(niri msg focused-window 2>/dev/null) || true
    
    if [ -z "$window_info" ]; then
        echo '{"text": "", "tooltip": "", "class": ""}'
        return
    fi
    
    if echo "$window_info" | grep -q "Is floating: yes"; then
        echo '{"text": "󱂬", "tooltip": "Floating window", "class": "floating"}'
    elif echo "$window_info" | grep -q "Is floating: no"; then
        echo '{"text": "󰕮", "tooltip": "Tiled window", "class": "tiled"}'
    else
        echo '{"text": "󰂭", "tooltip": "Unknown window state", "class": "unknown"}'
    fi
}

get_window_state
