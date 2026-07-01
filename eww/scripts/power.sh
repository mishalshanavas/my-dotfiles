#!/usr/bin/env bash
# Power menu via fuzzel

set -u

lock_file="${XDG_RUNTIME_DIR:-/tmp}/eww-power-menu.lock"
exec 9>"$lock_file"
flock -n 9 || exit 0

notify() {
    /usr/bin/notify-send "Power" "$1" 2>/dev/null || true
}

run_power_action() {
    local label="$1"
    shift
    local output

    if output=$("$@" 2>&1); then
        return 0
    fi

    notify "$label failed: ${output:-unknown error}"
    return 1
}

choice=$(printf '  Suspend\n  Reboot\n  Shutdown\n' | /usr/bin/fuzzel --dmenu -p "Power" --lines 3 --width 18)

case "$choice" in
    *Suspend*)
        run_power_action "Suspend" /usr/bin/systemctl --no-ask-password suspend
        ;;
    *Reboot*)
        run_power_action "Reboot" /usr/bin/systemctl --no-ask-password reboot
        ;;
    *Shutdown*)
        run_power_action "Shutdown" /usr/bin/systemctl --no-ask-password poweroff
        ;;
esac
