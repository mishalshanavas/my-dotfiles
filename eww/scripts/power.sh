#!/bin/sh
# Power menu via fuzzel

choice=$(printf '  Suspend\n  Reboot\n  Shutdown' | fuzzel --dmenu -p "Power" --lines 3 --width 18)
case "$choice" in
    *Suspend) systemctl suspend ;;
    *Reboot)  systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
