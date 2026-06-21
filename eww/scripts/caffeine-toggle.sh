#!/bin/sh
# Toggle caffeine (sleep inhibit) state

if [ -f "/tmp/caffeine-${UID}" ]; then
    rm -f "/tmp/caffeine-${UID}"
else
    touch "/tmp/caffeine-${UID}"
fi
