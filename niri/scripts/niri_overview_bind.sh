#!/usr/bin/env bash

# Use: niri_overview_bind.sh 'command with overview open' 'command with overview closed'
IS_IN_OVERVIEW=$(niri msg -j overview-state 2>/dev/null | jq -r '.is_open // false' 2>/dev/null)
if [[ "$IS_IN_OVERVIEW" == "true" ]]; then
  if [[ -n ${1:-} ]]; then
    niri msg action $1
  fi
else
  if [[ -n ${2:-} ]]; then
    niri msg action $2
  fi
fi
