#!/usr/bin/env bash
# Lock screen: screenshot → blur → lock
# Falls back gracefully if screenshot/blur fails

LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/swaylock-${UID}.lock"
BG="${XDG_CACHE_HOME:-$HOME/.cache}/lockscreen-blur.png"
TMP="/tmp/lockscreen-$$.png"

# If swaylock is already running, avoid doing expensive screenshot/blur work
# and avoid stacking lock processes.
pgrep -x swaylock >/dev/null 2>&1 && exit 0

# Prevent double-lock
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# Try to generate a fresh blurred background
if grim "$TMP" 2>/dev/null; then
    if ffmpeg -y -loglevel error -i "$TMP" \
        -vf "gblur=sigma=8" "$BG" 2>/dev/null; then
        rm -f "$TMP"
    else
        rm -f "$TMP"
        # ffmpeg failed, clear stale bg so we don't use broken file
        rm -f "$BG"
    fi
fi

# Lock with image if available, otherwise plain
if [[ -f "$BG" && -s "$BG" ]]; then
    exec swaylock --image "$BG" --scaling fill
else
    exec swaylock
fi
