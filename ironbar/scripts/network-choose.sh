#!/bin/sh
# Scan WiFi, show fuzzel menu, connect to chosen network
# Bluetooth tethering also listed if available

# Rescan then list available networks
networks=$(nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list --rescan yes 2>/dev/null | \
    awk -F: 'NF && $1 && $1 != "--" {sig=$3; if(sig+0>=75) s=""; else if(sig+0>=40) s=""; else s=""; printf "%s %s\n", s, $1}' | sort -u)

[ -z "$networks" ] && notify-send -t 2000 "WiFi" "No networks found" && exit 0

chosen=$(printf '%s' "$networks" | fuzzel --dmenu -p "  WiFi" --lines 12 --width 50)
[ -z "$chosen" ] && exit 0

ssid=$(printf '%s' "$chosen" | sed 's/^[^ ]* //')

# Check if already connected
if nmcli -t -f NAME con show --active 2>/dev/null | grep -Fxq "$ssid"; then
    notify-send -t 2000 "WiFi" "Already connected to $ssid"
    exit 0
fi

# Try connect
notify-send -t 3000 "WiFi" "Connecting to $ssid..."
nmcli dev wifi connect "$ssid" 2>/dev/null && \
    notify-send -t 3000 "WiFi" "Connected to $ssid" || \
    notify-send -u critical -t 4000 "WiFi" "Failed to connect to $ssid"
