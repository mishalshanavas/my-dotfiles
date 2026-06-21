#!/usr/bin/env bash
# Smart bluetooth click handler
# Off → power on + notify. On → open bluetuith.

power=$(/usr/bin/bluetoothctl show 2>/dev/null | awk '/Powered/ {print $2}')

if [ "$power" != "yes" ]; then
    /usr/bin/bluetoothctl power on 2>/dev/null
    /usr/bin/notify-send "Bluetooth" "Powered on" 2>/dev/null
else
    /usr/bin/ghostty -e /usr/bin/bluetuith &
fi
