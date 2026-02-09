#!/bin/bash

# Waybar script to show floating/tiled window state indicator

get_window_state() {
    local window_info=$(niri msg focused-window 2>/dev/null)
    
    if [ -z "$window_info" ]; then
        # No focused window or niri not running
        echo '{"text": "", "tooltip": "", "class": ""}'
        return
    fi
    
    if echo "$window_info" | grep -q "Is floating: yes"; then
        # Floating window
        echo '{"text": "", "tooltip": "Floating window", "class": "floating"}'
    elif echo "$window_info" | grep -q "Is floating: no"; then
        # Tiled window (grid layout)
        echo '{"text": "󰕮", "tooltip": "Tiled window", "class": "tiled"}'
    else
        # Unknown state
        echo '{"text": "󰂭", "tooltip": "Unknown window state", "class": "unknown"}'
    fi
}

get_window_state