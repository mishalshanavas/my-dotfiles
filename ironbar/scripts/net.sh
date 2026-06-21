#!/bin/sh
# Minimal network icon — MacBook-style
# nm-applet handles connections; this just shows status

if ! command -v nmcli >/dev/null 2>&1; then
    printf '  '
    exit 0
fi

state=$(nmcli -t -f TYPE,STATE,SIGNAL dev 2>/dev/null)

wifi_signal=$(echo "$state" | awk -F: '$1=="wifi" && $2=="connected" {print $3; exit}')
eth=$(echo "$state" | awk -F: '$1=="ethernet" && $2=="connected" {print $1; exit}')
connecting=$(nmcli -t -f STATE -e no dev 2>/dev/null | grep -q '^connecting$' && echo 1)

if [ -n "$wifi_signal" ]; then
    if [ "$wifi_signal" -ge 75 ]; then echo "󰤨"
    elif [ "$wifi_signal" -ge 50 ]; then echo "󰤥"
    elif [ "$wifi_signal" -ge 25 ]; then echo "󰤢"
    else echo "󰤟"
    fi
elif [ -n "$eth" ]; then
    echo "󰈀"
elif [ -n "$connecting" ]; then
    echo "󰤪"
else
    echo "󰤭"
fi
