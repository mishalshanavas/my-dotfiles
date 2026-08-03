#!/usr/bin/env bash
# One-shot caffeine status for scripts that do not use the active listener.

pid_file="${XDG_RUNTIME_DIR:-/tmp}/eww-caffeine.pid"
pid=$(cat "$pid_file" 2>/dev/null)

if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    printf '%s\n' $'\uefef'
else
    rm -f "$pid_file"
    printf '%s\n' $'\uf159'
fi
