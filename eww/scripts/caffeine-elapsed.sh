#!/usr/bin/env bash
# Report how long the current caffeine inhibitor has been running.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
source "$config_dir/eww/scripts/caffeine-state.sh"
pid=$(caffeine_main_pid) || exit 0

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
