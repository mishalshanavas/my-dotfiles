#!/bin/sh
# Toggle eww bar visibility

if eww active-windows 2>/dev/null | grep -q '^[^:][^:]*: bar$'; then
    eww close bar 2>/dev/null
else
    eww open --id primary bar 2>/dev/null
fi
