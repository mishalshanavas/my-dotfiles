#!/usr/bin/env bash
# Report the systemd-owned caffeine state to Eww.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
source "$config_dir/eww/scripts/caffeine-state.sh"
last=""

render() {
    if caffeine_active; then
        current="true"
    else
        current="false"
    fi

    if [ "$current" != "$last" ]; then
        printf '%s\n' "$current"
        last=$current
    fi
}

while true; do
    render
    sleep 2
done
