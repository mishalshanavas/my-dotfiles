#!/usr/bin/env bash
# Keep the laptop panel mirrored to the Epson projector whenever it is present.

set -u

source_output="${NIRI_MIRROR_SOURCE:-eDP-1}"
target_output="${NIRI_MIRROR_TARGET:-HDMI-A-1}"

while true; do
    if niri msg --json outputs 2>/dev/null | jq -e --arg output "$target_output" '.[$output].logical != null' >/dev/null; then
        # This exits when the projector disconnects, then the loop waits for it
        # to return. Niri supports screencopy-shm reliably on this system.
        wl-mirror --fullscreen-output "$target_output" --backend screencopy-shm "$source_output" || true
    fi

    sleep 2
done
