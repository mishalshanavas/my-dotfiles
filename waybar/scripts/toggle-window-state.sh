#!/bin/bash

# Toggle window floating/tiled state and show notification

toggle_window_state() {
    local window_info=$(niri msg focused-window 2>/dev/null)
    
    if [ -z "$window_info" ]; then
        notify-send "Window State" "No focused window" -i dialog-information
        return
    fi
    
    # Get window title for notification
    local window_title=$(echo "$window_info" | grep "Title:" | cut -d'"' -f2)
    [ ${#window_title} -gt 30 ] && window_title="${window_title:0:27}..."
    
    if echo "$window_info" | grep -q "Is floating: yes"; then
        # Currently floating, switch to tiled
        niri msg action toggle-window-floating
        notify-send "Window State" "󰕮 $window_title → Tiled" -i dialog-information -t 2000
    elif echo "$window_info" | grep -q "Is floating: no"; then
        # Currently tiled, switch to floating
        niri msg action toggle-window-floating  
        notify-send "Window State" " $window_title → Floating" -i dialog-information -t 2000
    else
        notify-send "Window State" "Unknown window state" -i dialog-warning
    fi
    
    # Show workspace summary after toggle
    sleep 0.2
    local windows_info=$(niri msg windows 2>/dev/null)
    local floating_count=$(echo "$windows_info" | grep -c "Is floating: yes" || echo "0")
    local tiled_count=$(echo "$windows_info" | grep -c "Is floating: no" || echo "0")
    
    if [ "$floating_count" -gt 0 ] && [ "$tiled_count" -gt 0 ]; then
        notify-send "Workspace" " $floating_count floating • 󰕮 $tiled_count tiled" -i dialog-information -t 1500
    elif [ "$floating_count" -gt 0 ] && [ "$tiled_count" -eq 0 ]; then
        notify-send "Workspace" " All windows floating ($floating_count)" -i dialog-information -t 1500
    elif [ "$floating_count" -eq 0 ] && [ "$tiled_count" -gt 0 ]; then
        notify-send "Workspace" "󰕮 All windows tiled ($tiled_count)" -i dialog-information -t 1500
    fi
    
    # Refresh waybar indicator
    pkill -RTMIN+9 waybar 2>/dev/null
}

toggle_window_state