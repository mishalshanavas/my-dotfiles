#!/bin/sh
if ! bluetoothctl show >/dev/null 2>&1; then
    exit 0
fi

powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}')
if [ "$powered" = "yes" ]; then
    bluetoothctl power off 2>/dev/null || true
else
    bluetoothctl power on 2>/dev/null || true
fi
