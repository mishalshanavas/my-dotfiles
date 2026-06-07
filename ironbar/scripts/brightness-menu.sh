#!/bin/sh
# Cycle brightness through presets: 100 → 75 → 50 → 25 → 10 → 100
command -v brightnessctl >/dev/null 2>&1 || exit 0

val=$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); print $4}')
[ -z "$val" ] && exit 0

# Find next lower preset (wrapping 10 → 100)
case 1 in
    $(( val >= 100 ))) new=75 ;;
    $(( val >= 75  ))) new=50 ;;
    $(( val >= 50  ))) new=25 ;;
    $(( val >= 25  ))) new=10 ;;
    $(( val >= 10  ))) new=100 ;;
    *)                 new=100 ;;
esac

brightnessctl set "${new}%" >/dev/null 2>&1 || true