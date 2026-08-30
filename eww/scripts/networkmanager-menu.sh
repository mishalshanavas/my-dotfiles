#!/usr/bin/env bash
# Refresh NetworkManager's access-point cache before opening the selector so
# nearby unsaved networks are included, not only known/active connections.

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
exec 9>"${runtime_dir}/eww-networkmanager-menu.lock"
flock -n 9 || exit 0

if [ "${1:-}" = "--tui" ]; then
    if command -v ghostty >/dev/null 2>&1 && command -v nmtui >/dev/null 2>&1; then
        exec ghostty -e nmtui
    fi
    notify-send "Network" "Ghostty or nmtui is not installed" 2>/dev/null || true
    exit 1
fi

# Resolve this repository's presentation wrapper by name. This keeps the INI
# portable while networkmanager-dmenu still recognizes the launcher as fuzzel.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
export PATH="$config_dir/eww/scripts:$PATH"

if command -v nmcli >/dev/null 2>&1; then
    # Refresh asynchronously so opening the picker is never blocked by a full
    # radio scan. NetworkManager's cache is used immediately and refreshed for
    # the next opening.
    nmcli device wifi rescan >/dev/null 2>&1 &
fi

exec networkmanager_dmenu
