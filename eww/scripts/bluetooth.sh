#!/usr/bin/env bash
# Eww deflisten — bluetooth status + auto audio switch
# Output: icon [device_name]

render() {
    local power connected dev_name

    power=$(bluetoothctl show 2>/dev/null | awk '/Powered/ {print $2}')

    if [ "$power" != "yes" ]; then
        printf '\n'
        return
    fi

    # Get first connected device info
    dev_name=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{$1=""; $2=""; sub(/^  /,""); print}')
    # Also check info for name
    if [ -z "$dev_name" ]; then
        dev_name=$(bluetoothctl info 2>/dev/null | awk -F': ' '/^[[:space:]]*Name:/ {print $2; exit}')
    fi

    if [ -n "$dev_name" ]; then
        # Limit length
        if [ "${#dev_name}" -gt 14 ]; then
            dev_name="${dev_name:0:13}…"
        fi
        printf ' %s\n' "$dev_name"
        auto_switch_sink "$dev_name"
    else
        printf '\n'
    fi
}

auto_switch_sink() {
    # Only switch if we just connected to a BT device (state change detected)
    # Check if this device was already seen
    local state_file="/tmp/eww_bt_last_device"
    local last
    last=$(cat "$state_file" 2>/dev/null)

    if [ "$1" != "$last" ]; then
        echo "$1" > "$state_file"
        # Try to switch to the BT sink
        local sink
        sink=$(pactl list short sinks 2>/dev/null | grep -i bluez | head -1 | awk '{print $1}')
        if [ -n "$sink" ]; then
            pactl set-default-sink "$sink" 2>/dev/null
        fi
    fi
}

render
while sleep 5; do
    render
done
