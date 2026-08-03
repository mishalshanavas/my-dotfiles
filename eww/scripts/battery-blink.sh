#!/bin/sh
# Toggle a blink flag every invocation. Eww defpoll runs this once per second;
# the battery widget combines this with the critical-state class to pulse.
flag="${XDG_RUNTIME_DIR:-/tmp}/eww-battery-blink"

if [ -f "$flag" ]; then
    rm -f "$flag"
    printf 'false\n'
else
    : > "$flag"
    printf 'true\n'
fi
