#!/bin/bash
set -uo pipefail

# Custom battery script for waybar with horizontal battery icons

get_battery_info() {
    local capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    local status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    
    if [ -z "${capacity:-}" ]; then
        echo '{"text": "", "tooltip": "No battery", "class": "no-battery"}'
        return
    fi
    
    local icon=""
    local class=""

    # Icon selection
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        icon="󱐋"
    else
        if [ "$capacity" -ge 95 ]; then icon="󰁹"
        elif [ "$capacity" -ge 85 ]; then icon="󰂂"
        elif [ "$capacity" -ge 75 ]; then icon="󰂁"
        elif [ "$capacity" -ge 65 ]; then icon="󰂀"
        elif [ "$capacity" -ge 55 ]; then icon="󰁿"
        elif [ "$capacity" -ge 45 ]; then icon="󰁾"
        elif [ "$capacity" -ge 35 ]; then icon="󰁽"
        elif [ "$capacity" -ge 25 ]; then icon="󰁼"
        elif [ "$capacity" -ge 15 ]; then icon="󰁻"
        else icon="󰁺"
        fi
    fi

    # Class selection (single unified block)
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        class="charging"
    elif [ "$capacity" -le 5 ]; then
        class="critical-blink"
    elif [ "$capacity" -le 15 ]; then
        class="critical"
    elif [ "$capacity" -le 30 ]; then
        class="warning"
    else
        class="normal"
    fi
    
    local tooltip="Battery: ${capacity}% (${status})"
    
    echo "{\"text\": \"${icon} ${capacity}\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
}

get_battery_info