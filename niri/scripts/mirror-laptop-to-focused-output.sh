#!/usr/bin/env bash
# Mirror the laptop panel to the currently focused external output.
# In Niri, focus the projector/TV first, then run this script.

set -u

source_output="eDP-1"

if ! command -v wl-mirror >/dev/null 2>&1; then
    notify-send "Screen mirroring unavailable" \
        "Install wl-mirror (Arch: sudo pacman -S wl-mirror), then try again." \
        -u critical
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    notify-send "Screen mirroring unavailable" "jq is required to identify the projector output." -u critical
    exit 1
fi

target_output="$(niri msg --json focused-output 2>/dev/null | jq -r '.name // empty')"

if [ -z "$target_output" ]; then
    notify-send "Screen mirroring unavailable" "Niri could not determine the focused display." -u critical
    exit 1
fi

if [ "$target_output" = "$source_output" ]; then
    notify-send "Choose the projector first" \
        "Focus the external display, then press Super+P to mirror the laptop screen to it." \
        -u normal
    exit 1
fi

notify-send "Starting screen mirror" "Mirroring $source_output to $target_output."
exec wl-mirror --fullscreen-output "$target_output" "$source_output"
