#!/usr/bin/env bash
# Lock screen: screenshot → blur → lock
# Falls back gracefully if screenshot/blur fails

set -u
umask 077

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${UID}}"
LOCK_FILE="$RUNTIME_DIR/swaylock.lock"
TMP_DIR=$(mktemp -d "$RUNTIME_DIR/swaylock.XXXXXX") || exit 1
BG="$TMP_DIR/lockscreen-blur.png"
TMP="$TMP_DIR/lockscreen.png"

cleanup() {
    rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT INT TERM

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
    swaylock --image "$BG" --scaling fill
else
    swaylock
fi
