#!/bin/bash
set -euo pipefail

# Toggle window floating/tiled state and show notification

toggle_window_state() {
    local window_info
    window_info=$(niri msg focused-window 2>/dev/null) || true
    
    if [ -z "$window_info" ]; then
        notify-send "Window State" "No focused window" -i dialog-information
        return
    fi
    
    # Get window title for notification
    local window_title
    window_title=$(echo "$window_info" | grep "Title:" | cut -d'"' -f2)
    [ ${#window_title} -gt 30 ] && window_title="${window_title:0:27}..."
    
    local new_state=""
    if echo "$window_info" | grep -q "Is floating: yes"; then
        new_state="Tiled"
    elif echo "$window_info" | grep -q "Is floating: no"; then
        new_state="Floating"
    else
        notify-send "Window State" "Unknown window state" -i dialog-warning
        return
    fi

    niri msg action toggle-window-floating

    # Single combined notification (no spam)
    sleep 0.15
    local windows_info
    windows_info=$(niri msg windows 2>/dev/null) || true
    local floating_count tiled_count
    floating_count=$(echo "$windows_info" | grep -c "Is floating: yes" || echo "0")
    tiled_count=$(echo "$windows_info" | grep -c "Is floating: no" || echo "0")
    
    local icon="󰕮"
    [[ "$new_state" == "Floating" ]] && icon="󱂬"

    notify-send "Window State" "$icon $window_title -> $new_state (󱂬 $floating_count 󰕮 $tiled_count)" -i dialog-information -t 2000
    
    # Refresh waybar indicator
    pkill -RTMIN+9 waybar 2>/dev/null || true
}

toggle_window_state
