#!/usr/bin/env bash
# Eww deflisten — MPRIS music via dbus
# Output: "icon title - artist" or "" (empty = hidden)

render() {
    local status artist title icon

    # Get first active MPRIS player
    local player
    player=$(dbus-send --session --dest=org.freedesktop.DBus \
        --type=method_call --print-reply /org/freedesktop/DBus \
        org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -o 'org.mpris.MediaPlayer2\.[^"]*' | head -1)

    if [ -z "$player" ]; then
        printf '\n'
        return
    fi

    # Get playback status
    status=$(dbus-send --session --dest="$player" --type=method_call \
        --print-reply /org/mpris/MediaPlayer2 \
        org.freedesktop.DBus.Properties.Get \
        string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null \
        | grep -o 'Playing\|Paused\|Stopped' | head -1)

    # Get metadata
    local metadata title artist
    metadata=$(dbus-send --session --dest="$player" --type=method_call \
        --print-reply /org/mpris/MediaPlayer2 \
        org.freedesktop.DBus.Properties.Get \
        string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)

    title=$(echo "$metadata" | awk '/xesam:title/{getline; sub(/.*string "/,""); sub(/".*/,""); print; exit}')
    # Artist is an array — get first string value after xesam:artist
    artist=$(echo "$metadata" | awk '/xesam:artist/{found=1; next} found && /string "/{sub(/.*string "/,""); sub(/".*/,""); print; exit}')

    [ -z "$title" ] && { printf '\n'; return; }

    if [ "$status" = "Playing" ]; then
        icon=''
    elif [ "$status" = "Paused" ]; then
        icon=''
    else
        icon=''
    fi

    local max=30
    if [ -n "$artist" ]; then
        local line
        line=$(printf '%s %s — %s' "$icon" "$title" "$artist")
        if [ "${#line}" -gt "$max" ]; then
            line="${line:0:$max}…"
        fi
        printf '%s\n' "$line"
    else
        local line
        line=$(printf '%s %s' "$icon" "$title")
        if [ "${#line}" -gt "$max" ]; then
            line="${line:0:$max}…"
        fi
        printf '%s\n' "$line"
    fi
}

render
# Watch DBus for MPRIS changes
dbus-monitor --session "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" 2>/dev/null \
    | grep -q --line-buffered 'MPRIS' | while IFS= read -r _; do
    render
done
