#!/bin/sh
if ! command -v nmcli >/dev/null 2>&1; then
    exit 0
fi

state=$(nmcli radio wifi 2>/dev/null)
if [ "$state" = "enabled" ]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
