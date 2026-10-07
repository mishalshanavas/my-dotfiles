#!/usr/bin/env bash
# Toggle the systemd-owned caffeine inhibitor.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
source "$config_dir/eww/scripts/caffeine-state.sh"

lock_file="${XDG_RUNTIME_DIR:-/tmp}/eww-caffeine.lock"
exec 9>"$lock_file"
flock -x 9

if caffeine_active; then
    systemctl --user stop eww-caffeine.service
else
    systemctl --user start eww-caffeine.service || {
        notify-send "Caffeine" "Failed to inhibit idle and sleep" 2>/dev/null || true
        exit 1
    }
fi
