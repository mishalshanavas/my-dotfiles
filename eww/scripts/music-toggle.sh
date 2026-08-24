#!/usr/bin/env bash

# Toggle the first available MPRIS player without requiring playerctl.
set -euo pipefail

mapfile -t players < <(
    dbus-send --session --dest=org.freedesktop.DBus \
        --type=method_call --print-reply /org/freedesktop/DBus \
        org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -o 'org.mpris.MediaPlayer2\.[^"]*' || true
)

player=${players[0]:-}
for candidate in "${players[@]}"; do
    status=$(dbus-send --session --dest="$candidate" --type=method_call \
        --print-reply /org/mpris/MediaPlayer2 \
        org.freedesktop.DBus.Properties.Get \
        string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null \
        | grep -o 'Playing\|Paused\|Stopped' | head -n 1 || true)
    if [[ "$status" == "Playing" ]]; then
        player=$candidate
        break
    fi
done

if [[ -n "$player" ]]; then
    dbus-send --session --dest="$player" --type=method_call \
        /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause >/dev/null
fi
