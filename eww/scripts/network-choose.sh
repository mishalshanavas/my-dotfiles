#!/usr/bin/env bash
# WiFi chooser via fuzzel + nmcli

wifi_list() {
    # Format: SSID|SIGNAL|SECURITY
    nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null \
        | awk -F: 'NF>=2 && $1!="" {
            sig = $2+0
            if (sig >= 75) bars = "4"
            else if (sig >= 50) bars = "3"
            else if (sig >= 25) bars = "2"
            else bars = "1"
            lock = ($3 != "" && $3 != "--") ? "*" : " "
            printf "%s|sig%s|%s\n", $1, bars, lock
        }' | sort -t'|' -k2,2r -u
}

# Display: "SSID  sigN  *"
list=$(wifi_list | awk -F'|' '{printf "%s\tsig%s  %s\n", $1, $2, $3}')
[ -z "$list" ] && { notify-send "WiFi" "No networks found" 2>/dev/null; exit 0; }

choice=$(echo "$list" | fuzzel --dmenu -p "WiFi" --lines 10 --width 34)
[ -z "$choice" ] && exit 0

# Extract SSID while preserving spaces in network names.
ssid=${choice%%	*}
[ -z "$ssid" ] && exit 0

# Get interface
iface=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')
[ -z "$iface" ] && iface="wlo1"

# Check if already connected to this SSID
current=$(nmcli -t -f CONNECTION dev show "$iface" 2>/dev/null | awk -F: '{print $2}')
if [ "$current" = "$ssid" ]; then
    notify-send "WiFi" "Already connected to $ssid" 2>/dev/null
    exit 0
fi

# Try connecting
output=$(nmcli dev wifi connect "$ssid" ifname "$iface" 2>&1)
ret=$?

if [ $ret -eq 0 ]; then
    notify-send "WiFi" "Connected to $ssid" 2>/dev/null
else
    # Check if password needed
    if echo "$output" | grep -qi "secrets\|password\|no network"; then
        notify-send "WiFi" "Password required for $ssid — use nmcli or nm-applet" 2>/dev/null
    else
        notify-send "WiFi" "Failed: $(echo "$output" | head -1)" 2>/dev/null
    fi
fi
