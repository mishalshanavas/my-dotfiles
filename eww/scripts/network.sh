#!/usr/bin/env bash
# Eww deflisten — network status via nmcli
# Safe Font Awesome icons only

render() {
    local state ssid eth connecting

    state=$(nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null)

    # WiFi
    ssid=$(echo "$state" | awk -F: '$1=="wifi" && $2=="connected" {print $3; exit}')
    if [ -n "$ssid" ]; then
        [ "${#ssid}" -gt 18 ] && ssid="${ssid:0:17}…"
        printf ' %s\n' "$ssid"
        return
    fi

    # Ethernet
    eth=$(echo "$state" | awk -F: '$1=="ethernet" && $2=="connected" {print $1; exit}')
    if [ -n "$eth" ]; then
        printf ' Wired\n'
        return
    fi

    # Connecting
    connecting=$(nmcli -t -f STATE -e no dev 2>/dev/null | grep -q '^connecting$' && echo 1)
    if [ -n "$connecting" ]; then
        printf ' …\n'
    else
        printf ' Off\n'
    fi
}

render
if command -v nmcli >/dev/null 2>&1; then
    nmcli monitor 2>/dev/null | while IFS= read -r line; do
        render
    done
fi

while sleep 10; do
    render
done
