#!/usr/bin/env bash
# Report how long the current caffeine inhibitor has been running.

pid_file="${XDG_RUNTIME_DIR:-/tmp}/eww-caffeine.pid"

[ -r "$pid_file" ] || exit 0
pid=$(cat "$pid_file" 2>/dev/null)
[[ "$pid" =~ ^[0-9]+$ ]] || exit 0
kill -0 "$pid" 2>/dev/null || exit 0

elapsed=$(ps -o etimes= -p "$pid" 2>/dev/null)
elapsed=${elapsed//[[:space:]]/}
[[ "$elapsed" =~ ^[0-9]+$ ]] || exit 0

hours=$((elapsed / 3600))
minutes=$(((elapsed % 3600) / 60))
seconds=$((elapsed % 60))

if ((hours > 0)); then
    printf '%d:%02d:%02d\n' "$hours" "$minutes" "$seconds"
else
    printf '%02d:%02d\n' "$minutes" "$seconds"
fi
