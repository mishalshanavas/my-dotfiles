#!/bin/bash

# Custom battery script for waybar with horizontal battery icons

get_battery_info() {
    local capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    local status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    
    if [ -z "$capacity" ]; then
        echo '{"text": "", "tooltip": "No battery", "class": "no-battery"}'
        return
    fi
    
    local icon=""
    local class=""
    
    # Horizontal battery icons based on capacity
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        # Lightning bolt for charging
        icon="󱐋"
        class="charging"
    else
        # Horizontal battery icons for discharging
        if [ "$capacity" -ge 95 ]; then
            icon="󰁹"
        elif [ "$capacity" -ge 85 ]; then
            icon="󰂂"
        elif [ "$capacity" -ge 75 ]; then
            icon="󰂁"
        elif [ "$capacity" -ge 65 ]; then
            icon="󰂀"
        elif [ "$capacity" -ge 55 ]; then
            icon="󰁿"
        elif [ "$capacity" -ge 45 ]; then
            icon="󰁾"
        elif [ "$capacity" -ge 35 ]; then
            icon="󰁽"
        elif [ "$capacity" -ge 25 ]; then
            icon="󰁼"
        elif [ "$capacity" -ge 15 ]; then
            icon="󰁻"
            class="warning"
        else
            icon="󰁺"
            class="critical"
        fi
    fi
    
    # Set class based on capacity if not charging
    if [ -z "$class" ]; then
        if [ "$capacity" -le 5 ]; then
            class="critical-blink"
        elif [ "$capacity" -le 15 ]; then
            class="critical"
        elif [ "$capacity" -le 30 ]; then
            class="warning"
        else
            class="normal"
        fi
    fi
    
    local tooltip="Battery: ${capacity}% (${status})"
    
    echo "{\"text\": \"${icon} ${capacity}\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
}

get_battery_info