#!/bin/sh
# Show detailed network status via notification
command -v nmcli >/dev/null 2>&1 || exit 0
command -v notify-send >/dev/null 2>&1 || exit 0

body=""

# Check Wi-Fi
wifi_state=$(nmcli -t -f STATE -e no dev 2>/dev/null | grep -c ':connected$' || true)
wifi_conn=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE -e no dev 2>/dev/null | awk -F: '$1=="wifi" && $2=="connected" {print $3,$4; exit}')
wifi_connecting=$(nmcli -t -f TYPE,STATE,CONNECTION -e no dev 2>/dev/null | awk -F: '$1=="wifi" && $2=="connecting" {print $3; exit}')

if [ -n "$wifi_conn" ]; then
    conn_name=${wifi_conn% *}
    device=${wifi_conn##* }
    signal=$(nmcli -t -f IN-USE,SIGNAL dev wifi list --rescan no 2>/dev/null | awk -F: '$1=="*" {print $2"%"; exit}')
    ip=$(nmcli -t -f IP4.ADDRESS dev show "$device" 2>/dev/null | awk -F'[:/]' '{print $2; exit}')
    body="${body}📶 ${conn_name}\n   Signal: ${signal:-?}\n   IP: ${ip:-?}\n\n"
elif [ -n "$wifi_connecting" ]; then
    body="${body}⏳ ${wifi_connecting}\n   Connecting...\n\n"
else
    # Check if Wi-Fi device exists but is disconnected
    wifi_hw=$(nmcli -t -f TYPE -e no dev 2>/dev/null | grep -c '^wifi$' || true)
    if [ "$wifi_hw" -gt 0 ]; then
        body="${body}📶 Wi-Fi\n   Disconnected\n\n"
    fi
fi

# Check Ethernet
eth_conn=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE -e no dev 2>/dev/null | awk -F: '$1=="ethernet" && $2=="connected" {print $3,$4; exit}')
if [ -n "$eth_conn" ]; then
    conn_name=${eth_conn% *}
    device=${eth_conn##* }
    ip=$(nmcli -t -f IP4.ADDRESS dev show "$device" 2>/dev/null | awk -F'[:/]' '{print $2; exit}')
    body="${body}🔌 ${conn_name}\n   IP: ${ip:-?}\n\n"
fi

if [ -z "$body" ]; then
    body="Offline — no active connections"
fi

notify-send -t 4000 "Network" "$body" 2>/dev/null || true
