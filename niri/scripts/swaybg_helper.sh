#!/bin/bash

# Script used to set or cycle background images using swaybg
# Can be called with flags:
#   -c or --cycle
#   -n or --notify
#   -d or --delay
# If no flag is provided, the last-used wallpaper will be set as the background

# Usage:
# To use in niri on startup (to set the initial background):
#   spawn-at-startup "bash" "/path/to/this_script.sh" "-f" "/home/mishal/.config/niri/wallpapers/"
# To bind to a key for cycling the wallpaper with a delay:
#   Mod+Shift+W { spawn "bash" "/path/to/this_script.sh" "--cycle" "-d"; }

# Path to folder containing wallpapers
BG_FOLDER_PATH="$HOME/.config/niri/wallpapers"

# Read script flags
FLAG_CYCLE=false
FLAG_NOTIFY=false
FLAG_DELAY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--cycle) FLAG_CYCLE=true ;;
    -n|--notify) FLAG_NOTIFY=true ;;
    -d|--delay) FLAG_DELAY=true ;;
    *) echo "Unknown option: $1" ;;
  esac
  shift
done

# Choose most-recent accessed file by default or least-recent to cycle
mapfile -t BG_PATHS < <(find "$BG_FOLDER_PATH" -maxdepth 1 -type f -printf '%A@ %p\n' | sort -rn | cut -d' ' -f2-)
if [[ ${#BG_PATHS[@]} -eq 0 ]]; then
  notify-send "Wallpaper" "No wallpapers found in $BG_FOLDER_PATH" 2>/dev/null || true
  exit 1
fi
BG_SELECT_PATH="${BG_PATHS[0]}"
if $FLAG_CYCLE; then
  BG_SELECT_PATH="${BG_PATHS[-1]}"
fi

# Notify if needed
if $FLAG_NOTIFY; then
  notify-send "Wallpaper Changed" "$(basename "$BG_SELECT_PATH")"
fi

# Get previous swaybg so we can stop it once we start a new instance
PREV_SWAYBG_PID=$(pidof swaybg)

# Update access on selected file, for cycling
touch -ac "$BG_SELECT_PATH"
swaybg -i "$BG_SELECT_PATH" &

# Wait a bit and then stop prior swaybg instances (if present)
if $FLAG_DELAY; then
  sleep 0.5
fi

# Close all prior swaybg instances (would be 'behind' current wallpaper)
if [[ -n "$PREV_SWAYBG_PID" ]]; then
  kill $PREV_SWAYBG_PID
fi
