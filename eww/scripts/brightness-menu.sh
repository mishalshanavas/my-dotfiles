#!/usr/bin/env bash
# Brightness quick menu for the Eww bar.

choice=$(printf 'Increase\nDecrease\n25%%\n50%%\n75%%\n100%%' | fuzzel --dmenu -p "Brightness" --lines 6 --width 16)
[ -z "$choice" ] && exit 0

case "$choice" in
    Increase)
        brightnessctl_arg="+10%"
        swayosd_arg="raise"
        ;;
    Decrease)
        brightnessctl_arg="10%-"
        swayosd_arg="lower"
        ;;
    *%)
        level=${choice%%%}
        case "$level" in
            ''|*[!0-9]*) exit 0 ;;
        esac
        brightnessctl_arg="${level}%"
        swayosd_arg="$level"
        ;;
    *)
        exit 0
        ;;
esac

if command -v brightnessctl >/dev/null 2>&1 && brightnessctl -c backlight set "$brightnessctl_arg" >/dev/null 2>&1; then
    if command -v swayosd-client >/dev/null 2>&1; then
        swayosd-client --brightness "+0" >/dev/null 2>&1 || true
    fi
    exit 0
fi

if command -v swayosd-client >/dev/null 2>&1 && swayosd-client --brightness "$swayosd_arg" >/dev/null 2>&1; then
    exit 0
fi

notify-send "Brightness" "Failed to set brightness" 2>/dev/null || true
exit 1
