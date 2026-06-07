#!/bin/sh
# Toggle caffeine: pause/resume swayidle
TOGGLE="/tmp/caffeine-${UID}"

if [ -f "$TOGGLE" ]; then
    rm -f "$TOGGLE"
    pkill -CONT swayidle 2>/dev/null
else
    touch "$TOGGLE"
    pkill -STOP swayidle 2>/dev/null
fi
