#!/bin/bash
set -euo pipefail

# WiFi menu - instant load using cached networks
# Configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE_FILE="$CACHE_DIR/wifi-networks.cache"
CACHE_DURATION=5  # seconds

mkdir -p "$CACHE_DIR"

# Improved process management
if pgrep -x fuzzel >/dev/null 2>&1; then
    pkill -x fuzzel 2>/dev/null
    sleep 0.05
fi

# Get cached or fresh network list
get_networks() {
    local cache_valid=false
    
    # Check if cache exists and is recent
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        [[ $cache_age -lt $CACHE_DURATION ]] && cache_valid=true
    fi
    
    if [[ "$cache_valid" != "true" ]]; then
        # Rebuild cache using \t delimiter to avoid SSID colon conflicts
        nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null | \
            grep -v '^--' | sort -t: -k2 -nr | awk '!seen[$0]++' > "$CACHE_FILE"
    fi
    
    cat "$CACHE_FILE"
}

# Get current connection
CURRENT=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1) || true

# Get networks (cached or fresh)
NETWORKS=$(get_networks)

# Format menu - track SSIDs in an associative array for later lookup
declare -A MENU_SSIDS
MENU=""
line_num=0
while IFS=: read -r ssid signal security; do
    [[ -z "$ssid" ]] && continue
    lock=""
    [[ -n "$security" ]] && lock="󰌾"
    if [[ "$ssid" == "$CURRENT" ]]; then
        MENU+="󰖩 $ssid $signal% $lock ●\n"
    else
        MENU+="󰖩 $ssid $signal% $lock\n"
    fi
    line_num=$((line_num + 1))
done <<< "$NETWORKS"

MENU+="──────────────\n"
MENU+="󰖪 Disconnect\n"
MENU+="󱛃 Rescan"

CHOSEN=$(echo -e "$MENU" | fuzzel --dmenu -p "WiFi: ") || true
[[ -z "${CHOSEN:-}" ]] && exit 0

if [[ "$CHOSEN" == *"Disconnect"* ]]; then
    nmcli device disconnect wlan0 2>/dev/null || nmcli device disconnect wifi 2>/dev/null || true
    notify-send "WiFi" "Disconnected"
elif [[ "$CHOSEN" == *"Rescan"* ]]; then
    rm -f "$CACHE_FILE"
    # Trigger rescan, wait briefly for hardware to respond
    nmcli device wifi rescan &>/dev/null || true
    sleep 0.5
    # Grab fresh list immediately
    nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null | \
        grep -v '^--' | sort -t: -k2 -nr | awk '!seen[$0]++' > "$CACHE_FILE" 2>/dev/null || true
    exec bash "$0"
else
    # Extract SSID: strip icon prefix, then strip everything from signal% onward
    SSID=$(echo "$CHOSEN" | awk '{
        sub(/^󰖩 /, "")
        sub(/ [0-9]+%.*$/, "")
        print
    }')
    
    # Validate SSID
    if [[ ${#SSID} -lt 1 || ${#SSID} -gt 32 ]]; then
        notify-send "WiFi" "Invalid network name"
        exit 1
    fi
    
    if nmcli connection show "$SSID" &>/dev/null; then
        nmcli connection up "$SSID" && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed"
    else
        if [[ "$CHOSEN" == *"󰌾"* ]]; then
            if pgrep -x fuzzel >/dev/null 2>&1; then
                pkill -x fuzzel 2>/dev/null
                sleep 0.05
            fi
            PASS=$(echo "" | fuzzel --dmenu -p "Password: " --password) || true
            [[ -z "${PASS:-}" ]] && exit 0
            nmcli device wifi connect "$SSID" password "$PASS" && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed"
        else
            nmcli device wifi connect "$SSID" && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed"
        fi
    fi
fi
