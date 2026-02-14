#!/bin/bash
# Dynamic CPU governor: performance on AC, powersave on battery
# Monitors power supply changes via udev events

set_governor() {
    local governor="$1"
    echo "$governor" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
}

check_and_set() {
    local ac_online
    for supply in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
        if [[ -f "$supply/online" ]]; then
            ac_online=$(cat "$supply/online")
            break
        fi
    done

    if [[ "$ac_online" == "1" ]]; then
        set_governor "performance"
    else
        set_governor "powersave"
    fi
}

# Set on startup
check_and_set

# Watch for power supply changes
while read -r _; do
    check_and_set
done < <(udevadm monitor --subsystem-match=power_supply --udev 2>/dev/null)
