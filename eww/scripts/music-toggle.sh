#!/usr/bin/env bash

# Toggle the first available MPRIS player without requiring playerctl.
set -euo pipefail

player=$(dbus-send --session --dest=org.freedesktop.DBus \
    --type=method_call --print-reply /org/freedesktop/DBus \
    org.freedesktop.DBus.ListNames 2>/dev/null \
    | grep -o 'org.mpris.MediaPlayer2\.[^"]*' | head -n 1)

if [[ -n "$player" ]]; then
    dbus-send --session --dest="$player" --type=method_call \
        /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause >/dev/null
fi
