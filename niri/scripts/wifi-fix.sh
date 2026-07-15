#!/usr/bin/env bash
# Auto-recover rtw88_8821ce WiFi when firmware gets stuck
# Runs at startup (via niri spawn, as user) and after suspend (via systemd, as root)

LOGFILE="/tmp/wifi-fix.log"
SUDO=""
[ "$(id -u)" != "0" ] && SUDO="sudo"

# Check if wifi is dead (no scan results, driver error)
if ! iw dev 2>/dev/null | grep -q 'Interface'; then
    echo "$(date): No WiFi interface found, reloading rtw88 driver" >> "$LOGFILE"
    $SUDO modprobe -r rtw88_8821ce rtw88_8821c rtw88_pci rtw88_core 2>/dev/null
    sleep 1
    $SUDO modprobe rtw88_8821ce 2>/dev/null
    sleep 2
fi

# If interface exists but can't scan, try a lighter reset
for iface in $(iw dev 2>/dev/null | grep Interface | awk '{print $2}'); do
    if iw dev "$iface" scan 2>&1 | grep -q 'No such device'; then
        echo "$(date): $iface scan failed, resetting" >> "$LOGFILE"
        $SUDO ip link set "$iface" down
        $SUDO ip link set "$iface" up
    fi
done
