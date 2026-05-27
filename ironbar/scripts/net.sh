#!/bin/sh
net_status() {
    if ! command -v nmcli >/dev/null 2>&1; then
        echo "   Net"
        return
    fi

    state=$(nmcli -t -f STATE general 2>/dev/null | head -n 1)
    if [ "$state" = "connecting" ]; then
        echo "   Connecting"
        return
    fi

    wifi=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | awk -F: '$2 == "wifi" && $3 == "connected" {print $4; exit}')
    if [ -n "$wifi" ]; then
        echo "   $wifi"
        return
    fi

    eth=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | awk -F: '$2 == "ethernet" && $3 == "connected" {print $4; exit}')
    if [ -n "$eth" ]; then
        echo "   $eth"
        return
    fi

    echo "   Offline"
}
net_status
nmcli monitor 2>/dev/null | grep --line-buffered -E "connected|disconnected|Wifi|connectivity" | while read -r _; do
    net_status
done
