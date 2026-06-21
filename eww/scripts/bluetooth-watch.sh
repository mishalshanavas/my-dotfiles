#!/usr/bin/env bash
# Eww deflisten — bluetooth status via dbus-monitor
# Display: icon + device name (connected) or icon + state text (idle/off)
# Auto-switches audio sink when BT device connects

AUDIO_SWITCHED_FILE="/tmp/eww_bt_audio_switched"

auto_switch_sink() {
    local dev_name="$1"
    local sink
    # Find bluez sink
    sink=$(pactl list short sinks 2>/dev/null | grep -i bluez | head -1 | awk '{print $1}')
    [ -z "$sink" ] && return
    # Only switch if this is a new connection
    local last
    last=$(cat "$AUDIO_SWITCHED_FILE" 2>/dev/null)
    [ "$dev_name" = "$last" ] && return
    pactl set-default-sink "$sink" 2>/dev/null
    echo "$dev_name" > "$AUDIO_SWITCHED_FILE"
}

render() {
    local power dev_name

    power=$(bluetoothctl show 2>/dev/null | awk '/Powered/ {print $2}')

    if [ "$power" != "yes" ]; then
        printf ' Off\n'
        return
    fi

    # Get connected device MAC, then resolve name
    local mac
    mac=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{print $2}')
    if [ -n "$mac" ]; then
        dev_name=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/^[[:space:]]*Name:/ {print $2; exit}')
        # Fallback to alias or raw name from devices list
        [ -z "$dev_name" ] && dev_name=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{$1=""; $2=""; sub(/^  /,""); print}')
    fi

    if [ -n "$dev_name" ]; then
        [ "${#dev_name}" -gt 16 ] && dev_name="${dev_name:0:15}…"
        printf ' %s\n' "$dev_name"
        auto_switch_sink "$dev_name"
    else
        printf ' On\n'
    fi
}

render
dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/bluez'" 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *PropertiesChanged*) render ;;
    esac
done
