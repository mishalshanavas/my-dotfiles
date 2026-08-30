#!/usr/bin/env bash
# Compact lock screen using the wallpaper cache prepared by swaybg_helper.sh.

set -u
umask 077
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${UID}}"
LOCK_FILE="$RUNTIME_DIR/swaylock.lock"
BACKGROUND="$RUNTIME_DIR/swaylock-background.png"

# If swaylock is already running, avoid doing expensive screenshot/blur work
# and avoid stacking lock processes.
pgrep -x swaylock >/dev/null 2>&1 && exit 0

# Prevent double-lock
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

if [[ -s "$BACKGROUND" ]]; then
    exec swaylock --image "$BACKGROUND" --scaling fill
else
    exec swaylock
fi
