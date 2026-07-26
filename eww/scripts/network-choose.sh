#!/usr/bin/env bash
# WiFi chooser via fuzzel + NetworkManager.

notify() {
    notify-send "WiFi" "$1" 2>/dev/null || true
}

open_tui() {
    if ! command -v nmtui >/dev/null 2>&1; then
        notify "nmtui is not installed"
        exit 1
    fi

    if command -v ghostty >/dev/null 2>&1; then
        exec ghostty -e nmtui
    fi

    notify "Ghostty is not installed; open nmtui from a terminal"
    exit 1
}

if [ "${1:-}" = "--tui" ]; then
    open_tui
fi

if ! command -v nmcli >/dev/null 2>&1; then
    notify "nmcli is not installed"
    exit 1
fi

if ! command -v fuzzel >/dev/null 2>&1; then
    notify "fuzzel is not installed"
    exit 1
fi

iface=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')
if [ -z "$iface" ]; then
    notify "No WiFi adapter found"
    exit 1
fi

if [ "$(nmcli -t -f WIFI general 2>/dev/null | head -n 1)" = "disabled" ]; then
    nmcli radio wifi on >/dev/null 2>&1 || {
        notify "Failed to enable WiFi"
        exit 1
    }
    sleep 1
fi

nmcli dev wifi rescan ifname "$iface" >/dev/null 2>&1 || true

wifi_list() {
    nmcli -t -e no -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list ifname "$iface" 2>/dev/null \
        | awk -F: '
        $2 != "" {
            ssid = $2
            sig = $3 + 0
            security = $4
            active = ($1 == "*") ? "connected" : ""

            if (!(ssid in best) || sig > best[ssid]) {
                best[ssid] = sig
                sec[ssid] = security
                cur[ssid] = active
            }
        }
        END {
            for (ssid in best) {
                sig = best[ssid]
                security = sec[ssid]
                active = cur[ssid]

                if (sig >= 75) bars = "4"
                else if (sig >= 50) bars = "3"
                else if (sig >= 25) bars = "2"
                else bars = "1"

                lock = (security != "" && security != "--") ? "locked" : "open"
                printf "%03d\t%s\tsig%s\t%s\t%s\t%s\n", sig, ssid, bars, lock, active, security
            }
        }' | sort -r -n | cut -f2-
}

list=$(wifi_list)
[ -z "$list" ] && { notify "No networks found"; exit 0; }

choice=$(printf '%s\n' "$list" | fuzzel --dmenu -p "WiFi" --lines 10 --width 42 \
    --only-match --with-nth=1,2,3,4 --accept-nth=1)
[ -z "$choice" ] && exit 0

ssid=$choice
[ -z "$ssid" ] && exit 0

current=$(nmcli -g GENERAL.CONNECTION dev show "$iface" 2>/dev/null | head -n 1)
if [ "$current" = "$ssid" ]; then
    notify "Already connected to $ssid"
    exit 0
fi

output=$(nmcli --wait 20 dev wifi connect "$ssid" ifname "$iface" 2>&1)
ret=$?

if [ $ret -eq 0 ]; then
    notify "Connected to $ssid"
    exit 0
fi

if printf '%s\n' "$output" | grep -Eiq "secrets|password|no valid secrets|802-11-wireless-security"; then
    password=$(fuzzel --dmenu --prompt-only="Password: " --password --width 34)
    [ -z "$password" ] && exit 0

    output=$(nmcli --wait 25 dev wifi connect "$ssid" password "$password" ifname "$iface" 2>&1)
    ret=$?

    if [ $ret -eq 0 ]; then
        notify "Connected to $ssid"
        exit 0
    fi
fi

notify "Failed: $(printf '%s\n' "$output" | head -n 1)"
exit 1
