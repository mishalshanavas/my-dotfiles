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

publish() {
    local current
    current=$(render)
    if [ "$current" != "$last" ]; then
        printf '%s\n' "$current"
        last=$current
    fi
}

publish

# NetworkManager emits state changes, so there is no need to wake up and fork
# several status commands every few seconds. Coalesce short bursts of events.
if command -v nmcli >/dev/null 2>&1; then
    nmcli monitor 2>/dev/null | while IFS= read -r _event; do
        sleep 0.15
        while IFS= read -r -t 0.02 _event; do :; done
        publish
    done
fi

# If the monitor exits, retain a slow recovery path instead of terminating the
# listener in a tight restart loop.
while sleep 30; do
    publish
done
