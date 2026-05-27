#!/bin/sh

visible=$(ironbar bar main get-visible 2>/dev/null)

if [ "$visible" = "true" ]; then
    # toggle off
    ironbar bar main set-visible false
else
    # show bar
    ironbar bar main set-visible true
fi
