#!/bin/bash

# Waybar startup script with system readiness check
# Ensures waybar starts only after essential services are ready

# Wait for niri to be fully ready
sleep 0.3

# Check if waybar is already running
if pgrep -x waybar >/dev/null 2>&1; then
    pkill waybar
    sleep 0.2
fi

# Wait for essential services to be available
for i in {1..10}; do
    # Check if PulseAudio/PipeWire is ready (for audio module)
    if command -v wpctl >/dev/null 2>&1 && wpctl get-volume @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1; then
        # Check if NetworkManager is ready (for network module) 
        if nmcli dev status >/dev/null 2>&1; then
            # Check if brightness control is ready
            if brightnessctl -l >/dev/null 2>&1; then
                break
            fi
        fi
    fi
    sleep 0.1
done

# Start waybar with proper error handling
exec waybar -c "/home/mishal/.config/waybar/config.jsonc" -s "/home/mishal/.config/waybar/style.css" 2>/dev/null