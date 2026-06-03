#!/bin/sh
choice=$(printf '󰐥  Shutdown\n󰜉  Reboot\n󰍃  Logout\n󰒲  Suspend' \
    | fuzzel --dmenu --prompt="Power " --width=40 --lines=4)

case "$choice" in
    *Shutdown*) systemctl poweroff ;;
    *Reboot*)   systemctl reboot ;;
    *Logout*)   niri msg action quit --skip-confirmation 2>/dev/null || true ;;
    *Suspend*)  systemctl suspend ;;
esac