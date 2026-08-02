#!/usr/bin/env bash
# Eww defpoll — bluetooth status (one-shot, exits after print)

power=$(bluetoothctl show 2>/dev/null | awk '/Powered/ {print $2}')

if [ "$power" != "yes" ]; then
    printf '%s\n' $'\ue1a7'
    exit 0
fi

dev_name=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{$1=""; $2=""; sub(/^  /,""); print}')
[ -z "$dev_name" ] && dev_name=$(bluetoothctl info 2>/dev/null | awk -F': ' '/^[[:space:]]*Name:/ {print $2; exit}')

if [ -n "$dev_name" ]; then
    if [ "${#dev_name}" -gt 14 ]; then
        dev_name="${dev_name:0:13}…"
    fi
    printf '%s %s\n' $'\ue1a8' "$dev_name"
else
    printf '%s\n' $'\ue1a7'
fi
