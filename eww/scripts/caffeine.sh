#!/bin/sh
# Eww defpoll — caffeine status
# Output: icon showing sleep state

uid=$(id -u)
file="${XDG_RUNTIME_DIR:-/tmp}/caffeine-${uid}"

if [ -f "$file" ]; then
    printf '%s\n' $'\uefef'
else
    printf '%s\n' $'\uf159'
fi
