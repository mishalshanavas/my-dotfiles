#!/bin/bash

# Script used to set or cycle background images using swaybg
# Can be called with flags:
#   -c or --cycle
#   -n or --notify
#   -d or --delay
# If no flag is provided, the last-used wallpaper will be set as the background.
# The selection is stored explicitly instead of relying on file access times
# (which may not update on noatime/relatime filesystems).

# Usage:
# To use in niri on startup (to set the initial background):
#   spawn-at-startup "sh" "-c" "exec \"${XDG_CONFIG_HOME:-$HOME/.config}/niri/scripts/swaybg_helper.sh\""
# To bind to a key for cycling the wallpaper with a delay:
#   Mod+Shift+W { spawn "bash" "/path/to/this_script.sh" "--cycle" "-d"; }

# Path to folder containing wallpapers
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BG_FOLDER_PATH="$CONFIG_DIR/niri/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/niri"
STATE_FILE="$STATE_DIR/wallpaper"

# Read script flags
FLAG_CYCLE=false
FLAG_NOTIFY=false
FLAG_DELAY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--cycle) FLAG_CYCLE=true ;;
    -n|--notify) FLAG_NOTIFY=true ;;
    -d|--delay) FLAG_DELAY=true ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# Keep the wallpaper list stable, so cycling has a predictable order.
mapfile -t BG_PATHS < <(
  find "$BG_FOLDER_PATH" -maxdepth 1 -type f \
    \( -iname '*.avif' -o -iname '*.bmp' -o -iname '*.jpeg' -o -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) \
    -print | LC_ALL=C sort
)
if [[ ${#BG_PATHS[@]} -eq 0 ]]; then
  notify-send "Wallpaper" "No wallpapers found in $BG_FOLDER_PATH" 2>/dev/null || true
  exit 1
fi

LAST_BG_PATH=""
if [[ -r "$STATE_FILE" ]]; then
  IFS= read -r LAST_BG_PATH < "$STATE_FILE" || true
fi

# On login, restore the previous choice when it is still in the wallpaper set.
BG_SELECT_PATH="${BG_PATHS[0]}"
for BG_PATH in "${BG_PATHS[@]}"; do
  if [[ "$BG_PATH" == "$LAST_BG_PATH" ]]; then
    BG_SELECT_PATH="$LAST_BG_PATH"
    break
  fi
done

if $FLAG_CYCLE; then
  # Start after the remembered wallpaper, wrapping at the end of the list.
  for INDEX in "${!BG_PATHS[@]}"; do
    if [[ "${BG_PATHS[$INDEX]}" == "$LAST_BG_PATH" ]]; then
      BG_SELECT_PATH="${BG_PATHS[$(( (INDEX + 1) % ${#BG_PATHS[@]} ))]}"
      break
    fi
  done
fi

# Notify if needed
if $FLAG_NOTIFY; then
  notify-send "Wallpaper Changed" "$(basename "$BG_SELECT_PATH")"
fi

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PID_FILE="$RUNTIME_DIR/niri-swaybg.pid"
LOCK_BACKGROUND="$RUNTIME_DIR/swaylock-background.png"
PREV_SWAYBG_PID=""
if [[ -r "$PID_FILE" ]]; then
  IFS= read -r PREV_SWAYBG_PID < "$PID_FILE" || true
  if [[ ! "$PREV_SWAYBG_PID" =~ ^[0-9]+$ ]] \
      || [[ ! -r "/proc/$PREV_SWAYBG_PID/comm" ]] \
      || [[ $(<"/proc/$PREV_SWAYBG_PID/comm") != "swaybg" ]]; then
    PREV_SWAYBG_PID=""
  fi
fi

# Save before launching swaybg so the choice survives an immediate reboot.
mkdir -p "$STATE_DIR"
STATE_TMP_FILE="$STATE_FILE.$$"
printf '%s\n' "$BG_SELECT_PATH" > "$STATE_TMP_FILE"
mv -f "$STATE_TMP_FILE" "$STATE_FILE"

# Build swaylock's blurred wallpaper outside the lock path. The lock screen can
# then appear immediately instead of capturing and filtering the live desktop.
if command -v ffmpeg >/dev/null 2>&1; then
  (
    exec 8>"$RUNTIME_DIR/swaylock-background.lock"
    flock -n 8 || exit 0
    LOCK_TMP=$(mktemp "$RUNTIME_DIR/swaylock-background.XXXXXX.png") || exit 0
    trap 'rm -f -- "$LOCK_TMP"' EXIT INT TERM
    if ffmpeg -y -loglevel error -i "$BG_SELECT_PATH" -frames:v 1 \
        -vf 'gblur=sigma=6,eq=brightness=0.06:contrast=0.92:saturation=0.75' \
        "$LOCK_TMP" 2>/dev/null; then
      mv -f -- "$LOCK_TMP" "$LOCK_BACKGROUND"
    fi
  ) &
fi

swaybg -i "$BG_SELECT_PATH" &
NEW_SWAYBG_PID=$!
printf '%s\n' "$NEW_SWAYBG_PID" > "$PID_FILE"

# Wait a bit and then stop prior swaybg instances (if present)
if $FLAG_DELAY; then
  sleep 0.5
fi

# Close all prior swaybg instances (would be 'behind' current wallpaper)
if [[ -n "$PREV_SWAYBG_PID" ]]; then
  kill "$PREV_SWAYBG_PID" 2>/dev/null || true
fi
