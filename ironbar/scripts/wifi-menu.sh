#!/bin/sh

prompt="Wi-Fi"

if ! command -v nmcli >/dev/null 2>&1; then
    printf "nmcli not found" | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=8
    exit 0
fi

nmcli radio wifi on

list=$(nmcli -t -f SSID,SECURITY,SIGNAL,ACTIVE dev wifi list --rescan no | awk -F: '$1 != "" { printf "%-20s | %s | %s%%\n", $1, $2, $3 }')

if [ -z "$list" ]; then
    printf "No networks found" | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=8
    exit 0
fi

choice=$(printf "%b" "$list" | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=8)
[ -z "$choice" ] && exit 0

ssid=$(echo "$choice" | awk -F' \| ' '{print $1}' | sed 's/ *$//')

nmcli dev wifi connect "$ssid"
