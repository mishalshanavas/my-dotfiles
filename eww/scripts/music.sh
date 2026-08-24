#!/usr/bin/env bash
# Eww deflisten — MPRIS music via dbus
# Output: "icon title - artist" or "" (empty = hidden)

render() {
    local status artist title icon

    # Prefer the actively playing MPRIS client; fall back to the first player.
    local player candidate
    local -a players
    mapfile -t players < <(dbus-send --session --dest=org.freedesktop.DBus \
        --type=method_call --print-reply /org/freedesktop/DBus \
        org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -o 'org.mpris.MediaPlayer2\.[^"]*')

    player=${players[0]:-}
    for candidate in "${players[@]}"; do
        status=$(dbus-send --session --dest="$candidate" --type=method_call \
            --print-reply /org/mpris/MediaPlayer2 \
            org.freedesktop.DBus.Properties.Get \
            string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null \
            | grep -o 'Playing\|Paused\|Stopped' | head -1)
        if [ "$status" = "Playing" ]; then
            player=$candidate
            break
        fi
    done

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
    local metadata
    metadata=$(dbus-send --session --dest="$player" --type=method_call \
        --print-reply /org/mpris/MediaPlayer2 \
        org.freedesktop.DBus.Properties.Get \
        string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)

    title=$(echo "$metadata" | awk '/xesam:title/{getline; sub(/.*string "/,""); sub(/".*/,""); print; exit}')
    # Artist is an array — get first string value after xesam:artist
    artist=$(echo "$metadata" | awk '/xesam:artist/{found=1; next} found && /string "/{sub(/.*string "/,""); sub(/".*/,""); print; exit}')

    [ -z "$title" ] && { printf '\n'; return; }

    if [ "$status" = "Playing" ]; then
        icon='Ⅱ'
    elif [ "$status" = "Paused" ]; then
        icon='▶'
    else
        icon='▶'
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
# Watch DBus for MPRIS changes. If dbus-monitor is unavailable or exits, fall
# back to a light poll so the Eww listener keeps producing updates.
if command -v dbus-monitor >/dev/null 2>&1; then
    dbus-monitor --session \
        "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'" \
        "type='signal',interface='org.freedesktop.DBus',member='NameOwnerChanged',arg0namespace='org.mpris.MediaPlayer2'" \
        2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *"member=PropertiesChanged"*|*"member=NameOwnerChanged"*) render ;;
        esac
    done
fi

while sleep 5; do
    render
done
