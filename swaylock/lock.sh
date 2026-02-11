#!/usr/bin/env bash
# Lock screen script with blurred screenshot for niri/swaylock
# Best practices: atomic operations, proper error handling, race condition prevention

set -euo pipefail

LOCK_FILE="/tmp/swaylock-$UID.lock"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
BLUR_IMAGE="$CACHE_DIR/lockscreen-blur.png"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE" "/tmp/lockscreen-$$-*.png" 2>/dev/null || true
}
trap cleanup EXIT

# Prevent multiple instances using flock
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Take screenshot and blur it
take_and_blur_screenshot() {
    local tmp_screenshot="/tmp/lockscreen-$$-$(date +%s%N).png"
    
    # Try grim for screenshot (works with wlroots compositors including niri)
    if command -v grim &>/dev/null && grim "$tmp_screenshot" 2>/dev/null; then
        # Try ffmpeg for fast blur
        if command -v ffmpeg &>/dev/null; then
            if ffmpeg -loglevel error -i "$tmp_screenshot" -vf "gblur=sigma=30,brightness=-0.05" -y "$BLUR_IMAGE" 2>/dev/null; then
                # Verify blur was successful
                if [[ -f "$BLUR_IMAGE" && -s "$BLUR_IMAGE" ]]; then
                    rm -f "$tmp_screenshot"
                    return 0
                fi
            fi
        fi
        
        # Fallback: ImageMagick convert
        if command -v magick &>/dev/null; then
            if magick "$tmp_screenshot" -blur 0x12 -modulate 95 "$BLUR_IMAGE" 2>/dev/null; then
                # Verify conversion was successful
                if [[ -f "$BLUR_IMAGE" && -s "$BLUR_IMAGE" ]]; then
                    rm -f "$tmp_screenshot"
                    return 0
                fi
            fi
        elif command -v convert &>/dev/null; then
            if convert "$tmp_screenshot" -blur 0x12 -modulate 95 "$BLUR_IMAGE" 2>/dev/null; then
                # Verify conversion was successful
                if [[ -f "$BLUR_IMAGE" && -s "$BLUR_IMAGE" ]]; then
                    rm -f "$tmp_screenshot"
                    return 0
                fi
            fi
        fi
        
        rm -f "$tmp_screenshot"
    fi
    
    return 1
}

# Try to create blurred screenshot, fall back to solid color
if ! take_and_blur_screenshot; then
    # Remove stale image to let swaylock use solid color from config
    rm -f "$BLUR_IMAGE" 2>/dev/null || true
fi

# Lock the screen
# Note: swaylock reads config from ~/.config/swaylock/config
if [[ -f "$BLUR_IMAGE" ]]; then
    exec swaylock --daemonize --image "$BLUR_IMAGE" --scaling fill
else
    exec swaylock --daemonize
fi
