#!/usr/bin/env bash
# Eww deflisten — brightness via backlight sysfs
# Output: "icon percentage%"

backlight_path() {
    for dev in /sys/class/backlight/*; do
        [ -r "$dev/brightness" ] && [ -r "$dev/max_brightness" ] || continue
        printf '%s\n' "$dev"
        return 0
    done
    return 1
}

render() {
    local cur max pct icon
    [ -z "$BL_PATH" ] && { printf ' N/A\n'; return; }

    cur=$(tr -cd '0-9' < "$BL_PATH/brightness")
    max=$(tr -cd '0-9' < "$BL_PATH/max_brightness")

    if [ -z "$cur" ] || [ -z "$max" ] || [ "$max" -eq 0 ]; then
        printf ' N/A\n'
        return
    fi

    pct=$(( (100 * cur + max / 2) / max ))

    printf ' %s%%\n' "$pct"
}

BL_PATH=$(backlight_path)
render

if [ -z "$BL_PATH" ]; then
    # No backlight, exit — variable stays with initial value
    sleep infinity
fi

# Watch with inotify for instant updates
if command -v inotifywait >/dev/null 2>&1; then
    inotifywait -m -e modify -e close_write "$BL_PATH/brightness" 2>/dev/null | while IFS= read -r _; do
        render
    done
else
    while sleep 1; do render; done
fi
