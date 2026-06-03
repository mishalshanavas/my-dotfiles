#!/bin/sh
visible=$(ironbar bar main get-visible 2>/dev/null) || exit 0

case "$visible" in
    true)  ironbar bar main set-visible false ;;
    false) ironbar bar main set-visible true  ;;
esac