#!/bin/bash

# WiFi menu - instant load using cached networks
pkill -x fuzzel 2>/dev/null
sleep 0.05

# Get current connection
CURRENT=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

# List cached networks (--rescan no = instant)
NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null | grep -v '^--' | sort -t: -k2 -nr | uniq)

# Format menu
MENU=""
while IFS=: read -r ssid signal security; do
    [[ -z "$ssid" ]] && continue
    lock=""
    [[ -n "$security" ]] && lock="󰌾"
    if [[ "$ssid" == "$CURRENT" ]]; then
        MENU+="󰖩 $ssid $signal% $lock ●\n"
    else
        MENU+="󰖩 $ssid $signal% $lock\n"
    fi
done <<< "$NETWORKS"

MENU+="──────────────\n"
MENU+="󰖪 Disconnect\n"
MENU+="󱛃 Rescan"

CHOSEN=$(echo -e "$MENU" | fuzzel --dmenu -p "WiFi: ")
[[ -z "$CHOSEN" ]] && exit 0

if [[ "$CHOSEN" == *"Disconnect"* ]]; then
    nmcli device disconnect wlan0 2>/dev/null || nmcli device disconnect wifi 2>/dev/null
    notify-send "WiFi" "Disconnected"
elif [[ "$CHOSEN" == *"Rescan"* ]]; then
    notify-send "WiFi" "Scanning..."
    nmcli device wifi rescan 2>/dev/null
    sleep 2
    exec "$0"
else
    SSID=$(echo "$CHOSEN" | sed 's/󰖩 //' | sed 's/ [0-9]*%.*//' | sed 's/[^a-zA-Z0-9._: -]//g')
    # Validate SSID length and characters
    if [[ ${#SSID} -lt 1 || ${#SSID} -gt 32 ]]; then
        notify-send "WiFi" "Invalid network name"
        exit 1
    fi
    
    if nmcli connection show "$SSID" &>/dev/null; then
        nmcli connection up "$SSID" && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed"
    else
        if [[ "$CHOSEN" == *"󰌾"* ]]; then
            pkill -x fuzzel 2>/dev/null; sleep 0.05
            PASS=$(echo "" | fuzzel --dmenu -p "Password: " --password)
            [[ -z "$PASS" ]] && exit 0
            nmcli device wifi connect "$SSID" password "$PASS" && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed"
        else
            nmcli device wifi connect "$SSID" && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed"
        fi
    fi
fi
