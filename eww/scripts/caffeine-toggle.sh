#!/bin/sh
# Toggle caffeine (sleep inhibit) state

uid=$(id -u)
file="${XDG_RUNTIME_DIR:-/tmp}/caffeine-${uid}"

if [ -f "$file" ]; then
    rm -f "$file"
else
    touch "$file"
fi
