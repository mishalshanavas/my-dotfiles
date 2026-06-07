#!/bin/sh
# Check toggle file for caffeine state
[ -f "/tmp/caffeine-${UID}" ] && printf '󰅶 on\n' || printf '󰅶 off\n'
