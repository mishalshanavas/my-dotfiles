#!/usr/bin/env bash

set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

find_niri_socket() {
    if [[ -n "${NIRI_SOCKET:-}" && -S "$NIRI_SOCKET" ]]; then
        printf '%s\n' "$NIRI_SOCKET"
        return 0
    fi

    find "$runtime_dir" -maxdepth 1 -type s -name 'niri.*.sock' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn \
        | awk 'NR == 1 {print $2}'
}

for _ in {1..200}; do
    socket_path="$(find_niri_socket)"
    if [[ -n "$socket_path" && -S "$socket_path" ]]; then
        export NIRI_SOCKET="$socket_path"
        exec /usr/bin/python3 /home/mishal/.config/niri/scripts/niri_tile_to_n.py -n 3 -delay 2000
    fi
    sleep 0.1
done

printf 'Timed out waiting for Niri IPC socket in %s\n' "$runtime_dir" >&2
exit 1
