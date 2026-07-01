#!/bin/sh
# Eww defpoll — caffeine status
# Output: icon showing sleep state

uid=$(id -u)
file="${XDG_RUNTIME_DIR:-/tmp}/caffeine-${uid}"

if [ -f "$file" ]; then
    printf '\n'
else
    printf '\n'
fi
