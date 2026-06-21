#!/usr/bin/env bash
# Bluetooth device chooser — scan, pair, connect via fuzzel

power=$(bluetoothctl show 2>/dev/null | awk '/Powered/ {print $2}')
if [ "$power" != "yes" ]; then
    # Turn on first
    bluetoothctl power on 2>/dev/null
    sleep 1
fi

# Start scan in background
bluetoothctl scan on 2>/dev/null &
scan_pid=$!
sleep 4
bluetoothctl scan off 2>/dev/null
kill $scan_pid 2>/dev/null

# Build device list: paired first, then discovered
{
    # Paired devices
    bluetoothctl devices Paired 2>/dev/null | while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{$1=""; print}' | sed 's/^[[:space:]]*//')
        if bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'; then
            printf '✓ %s\n' "$name"
        else
            printf '  %s\n' "$name"
        fi
    done

    # Discovered (unpaired) devices
    bluetoothctl devices 2>/dev/null | while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{$1=""; print}' | sed 's/^[[:space:]]*//')
        # Skip if already shown as paired
        bluetoothctl info "$mac" 2>/dev/null | grep -q 'Paired: yes' && continue
        printf '+ %s\n' "$name"
    done
} | sort -u > /tmp/bt_devices

devices=$(cat /tmp/bt_devices)
[ -z "$devices" ] && { notify-send "No devices found" 2>/dev/null || true; exit 0; }

choice=$(echo "$devices" | fuzzel --dmenu -p "Bluetooth" --lines 10 --width 32)
[ -z "$choice" ] && exit 0

# Strip prefix markers
clean=$(echo "$choice" | sed 's/^✓ //; s/^+ //; s/^  //')

# Find device MAC
mac=$(bluetoothctl devices 2>/dev/null | grep -F "$clean" | awk '{print $2}')
[ -z "$mac" ] && exit 0

# Action: connected → disconnect, otherwise → connect (and pair if needed)
if echo "$choice" | grep -q '^✓'; then
    bluetoothctl disconnect "$mac" 2>/dev/null
else
    bluetoothctl connect "$mac" 2>/dev/null || {
        # Try pairing first
        bluetoothctl pair "$mac" 2>/dev/null
        sleep 1
        bluetoothctl connect "$mac" 2>/dev/null
    }
    # Trust device for auto-reconnect
    bluetoothctl trust "$mac" 2>/dev/null
fi

rm -f /tmp/bt_devices
