#!/bin/sh
choice=$(printf "󰐥  Shutdown\n󰜉  Reboot\n󰍃  Logout\n󰒲  Suspend" | fuzzel --dmenu --prompt="Power" --width=40 --lines=8)
case "$choice" in
*Shutdown*) systemctl poweroff ;;
*Reboot*)   systemctl reboot ;;
*Logout*)   niri msg action quit --skip-confirmation ;;
*Suspend*)  systemctl suspend ;;
esac
