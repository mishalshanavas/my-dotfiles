#!/bin/sh
prompt="Wi-Fi"

command -v nmcli >/dev/null 2>&1 || {
    printf 'nmcli not found' | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=1
    exit 0
}

# Don't touch wifi radio state — respect whatever the user has set.
wifi_state=$(nmcli radio wifi 2>/dev/null)
if [ "$wifi_state" = "disabled" ]; then
    choice=$(printf 'Enable Wi-Fi\nCancel' \
        | fuzzel --dmenu --prompt="Wi-Fi is off  " --width=40 --lines=2)
    case "$choice" in
        'Enable Wi-Fi') nmcli radio wifi on ;;
    esac
    exit 0
fi

# Scan. Use cached results first for speed; fall back to live scan if empty.
# -e no: don't escape special chars, so SSIDs with colons/backslashes survive.
# Use \t as separator to avoid splitting on colons in SSIDs.
parse_list='
    NR > 1 { next }   # skip header line from non-terse mode
    1
'

raw=$(nmcli -t -f SSID,SECURITY,SIGNAL,ACTIVE -e no dev wifi list --rescan no 2>/dev/null)
if [ -z "$raw" ]; then
    raw=$(nmcli -t -f SSID,SECURITY,SIGNAL,ACTIVE -e no dev wifi list 2>/dev/null)
fi

if [ -z "$raw" ]; then
    printf 'No networks found' | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=1
    exit 0
fi

# nmcli -t -e no with SSID,SECURITY,SIGNAL,ACTIVE outputs colon-separated fields.
# With -e no, colons inside field values are NOT escaped — so we can't reliably
# split on colon when SSIDs contain colons. Use ACTIVE as a known-last field anchor
# and build display lines with the SSID verbatim instead.
list=$(printf '%s\n' "$raw" | while IFS= read -r line; do
    [ -n "$line" ] || continue

    active=${line##*:}
    line=${line%:*}
    signal=${line##*:}
    line=${line%:*}
    security=${line##*:}
    ssid=${line%:*}

    [ -n "$ssid" ] || continue

    marker='  '
    [ "$active" = "yes" ] && marker=' ✓'
    printf '%s\t%s\t%s\t%s\n' "$marker" "$ssid" "$security" "$signal"
done)

choice=$(printf '%s\n' "$list" | fuzzel --dmenu --prompt="$prompt  " --width=56 --lines=10)
[ -z "$choice" ] && exit 0

# The menu rows are tab-separated: marker, SSID, security, signal.
ssid=$(printf '%s' "$choice" | cut -f2)
security=$(printf '%s' "$choice" | cut -f3)

# If already connected to this network, offer to disconnect instead
current=$(nmcli -t -f NAME,TYPE con show --active 2>/dev/null \
    | awk -F: '$2 == "802-11-wireless" {print $1; exit}')
if [ "$ssid" = "$current" ]; then
    action=$(printf 'Disconnect\nCancel' \
        | fuzzel --dmenu --prompt="$ssid  " --width=40 --lines=2)
    case "$action" in
        Disconnect) nmcli con down "$ssid" 2>/dev/null || true ;;
    esac
    exit 0
fi

# Check if we have a saved profile — if so, just activate it (no password prompt).
saved=$(nmcli -t -f NAME con 2>/dev/null | grep -Fx "$ssid")
if [ -n "$saved" ]; then
    nmcli con up "$ssid" 2>/dev/null || true
    exit 0
fi

if [ -z "$security" ] || [ "$security" = "--" ]; then
    # Open network
    nmcli dev wifi connect "$ssid" 2>/dev/null || true
else
    pass=$(fuzzel --dmenu --prompt="Password for $ssid: " --width=44 --lines=0 --password)
    [ -z "$pass" ] && exit 0
    nmcli dev wifi connect "$ssid" password "$pass" 2>/dev/null || true
fi