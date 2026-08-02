#!/usr/bin/env bash
# Eww deflisten — network status via NetworkManager.

truncate_label() {
    local text="$1"
    local max="${2:-18}"

    if [ "${#text}" -gt "$max" ]; then
        printf '%s…' "${text:0:max-1}"
    else
        printf '%s' "$text"
    fi
}

render() {
    local state iface label eth connecting radio wifi_icon ethernet_icon
    wifi_icon=$'\ue63e'
    ethernet_icon=$'\ue8be'

    if ! command -v nmcli >/dev/null 2>&1; then
        printf '%s N/A\n' "$wifi_icon"
        return
    fi

    state=$(nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null)

    iface=$(printf '%s\n' "$state" | awk -F: '$2=="wifi" && $3=="connected" {print $1; exit}')
    if [ -n "$iface" ]; then
        label=$(nmcli -g GENERAL.CONNECTION dev show "$iface" 2>/dev/null | head -n 1)
        [ -z "$label" ] || [ "$label" = "--" ] && label="WiFi"
        label=$(truncate_label "$label" 18)
        printf '%s %s\n' "$wifi_icon" "$label"
        return
    fi

    eth=$(printf '%s\n' "$state" | awk -F: '$2=="ethernet" && $3=="connected" {print $1; exit}')
    if [ -n "$eth" ]; then
        printf '%s Wired\n' "$ethernet_icon"
        return
    fi

    connecting=$(printf '%s\n' "$state" | awk -F: '$2=="wifi" && $3 ~ /(connecting|configuring|prepare|need-auth)/ {print 1; exit}')
    if [ -n "$connecting" ]; then
        printf '%s …\n' "$wifi_icon"
        return
    fi

    radio=$(nmcli -t -f WIFI general 2>/dev/null | head -n 1)
    if [ "$radio" = "disabled" ]; then
        printf '%s Off\n' "$wifi_icon"
    else
        printf '%s Down\n' "$wifi_icon"
    fi
}

last=""

while true; do
    current=$(render)
    if [ "$current" != "$last" ]; then
        printf '%s\n' "$current"
        last=$current
    fi
    sleep 3
done
