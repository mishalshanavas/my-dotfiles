#!/usr/bin/env bash
# Eww deflisten — bluetooth status via BlueZ D-Bus events.
# Display: icon + device name when connected, icon + state when off, or
# nothing when Bluetooth is powered on but disconnected.
# Auto-switches audio sink when BT device connects

AUDIO_SWITCHED_FILE="${XDG_RUNTIME_DIR:-/tmp}/eww_bt_audio_switched"

auto_switch_sink() {
    local mac="$1"
    local device_id sink
    device_id="bluez_output.${mac//:/_}"
    sink=$(pactl list short sinks 2>/dev/null | awk -v device_id="$device_id" 'index($2, device_id) == 1 { print $2; exit }')
    [ -z "$sink" ] && return

    local last
    last=$(cat "$AUDIO_SWITCHED_FILE" 2>/dev/null)
    [ "$mac" = "$last" ] && return
    pactl set-default-sink "$sink" 2>/dev/null || return
    printf '%s\n' "$mac" > "$AUDIO_SWITCHED_FILE"
}

render() {
    local power dev_name

    power=$(bluetoothctl show 2>/dev/null | awk '/Powered/ {print $2}')

    if [ "$power" != "yes" ]; then
        printf '%s Off\n' $'\ue1a9'
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
        # If the device name is a raw MAC address (unresolved SDP name), show "Connecting..."
        if [[ "$dev_name" =~ ^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$ ]]; then
            dev_name="Connecting..."
        fi
        [ "${#dev_name}" -gt 16 ] && dev_name="${dev_name:0:15}…"
        printf '%s %s\n' $'\ue1a8' "$dev_name"
        auto_switch_sink "$mac"
    else
        rm -f "$AUDIO_SWITCHED_FILE"
        printf '\n'
    fi
}

render

if command -v dbus-monitor >/dev/null 2>&1; then
    # Reconnect if D-Bus restarts. Rendering only on BlueZ changes avoids
    # repeatedly waking the CPU and querying bluetoothctl while idle.
    while :; do
        dbus-monitor --system \
            "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" \
            2>/dev/null | while IFS= read -r line; do
                case "$line" in
                    *"member=PropertiesChanged"*) render ;;
                esac
            done
        sleep 2
    done
else
    # Fallback for systems without dbus-monitor.
    while sleep 30; do
        render
    done
fi
