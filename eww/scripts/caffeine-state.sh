#!/usr/bin/env bash
# The inhibitor is owned by systemd, independent of the Eww click process.

caffeine_active() {
    systemctl --user is-active --quiet eww-caffeine.service
}

caffeine_main_pid() {
    local pid
    caffeine_active || return 1
    pid=$(systemctl --user show eww-caffeine.service --property=MainPID --value 2>/dev/null) || return 1
    [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
    printf '%s\n' "$pid"
}
