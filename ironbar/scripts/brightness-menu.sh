#!/bin/sh
prompt="Brightness"

if ! command -v brightnessctl >/dev/null 2>&1; then
    printf "brightnessctl not found" | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=8
    exit 0
fi

menu="10%\n25%\n50%\n75%\n100%\n+5%\n-5%"
choice=$(printf "%b" "$menu" | fuzzel --dmenu --prompt="$prompt" --width=40 --lines=8)
[ -z "$choice" ] && exit 0

case "$choice" in
    "+5%") "$HOME/.config/ironbar/scripts/brightness-step.sh" up ;;
    "-5%") "$HOME/.config/ironbar/scripts/brightness-step.sh" down ;;
    *) brightnessctl set "$choice" ;;
esac
