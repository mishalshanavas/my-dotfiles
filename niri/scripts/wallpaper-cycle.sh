#!/bin/bash
# Wallpaper cycling script for niri/swaybg

WALLPAPER_DIR="$HOME/.config/niri/wallpapers"
STATE_FILE="$HOME/.config/niri/.wallpaper-index"

# Get list of wallpapers
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort)

# Get total count
TOTAL=${#WALLPAPERS[@]}

if [ $TOTAL -eq 0 ]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Read current index
if [ -f "$STATE_FILE" ]; then
    CURRENT=$(cat "$STATE_FILE")
    # Ensure CURRENT is a valid number and within range
    if ! [[ "$CURRENT" =~ ^[0-9]+$ ]] || [ "$CURRENT" -ge "$TOTAL" ]; then
        CURRENT=0
    fi
else
    CURRENT=0
fi

# Handle arguments
case "$1" in
    next)
        CURRENT=$(( (CURRENT + 1) % TOTAL ))
        ;;
    prev)
        CURRENT=$(( (CURRENT - 1 + TOTAL) % TOTAL ))
        ;;
    random)
        CURRENT=$(( RANDOM % TOTAL ))
        ;;
    preview)
        # Preview current wallpaper info without changing
        WALLPAPER="${WALLPAPERS[$CURRENT]}"
        BASENAME=$(basename "$WALLPAPER")
        notify-send "Wallpaper Preview" "$BASENAME ($(($CURRENT + 1))/$TOTAL)" -t 2000
        exit 0
        ;;
    fav)
        # Add current wallpaper to favorites
        WALLPAPER="${WALLPAPERS[$CURRENT]}"
        FAV_FILE="$HOME/.config/niri/favorite-wallpapers"
        echo "$WALLPAPER" >> "$FAV_FILE"
        BASENAME=$(basename "$WALLPAPER")
        notify-send "Wallpaper" "Added $BASENAME to favorites" -t 2000
        exit 0
        ;;
    list)
        # List all wallpapers
        for i in "${!WALLPAPERS[@]}"; do
            BASENAME=$(basename "${WALLPAPERS[$i]}")
            if [[ $i -eq $CURRENT ]]; then
                echo "● $((i + 1)): $BASENAME (current)"
            else
                echo "  $((i + 1)): $BASENAME"
            fi
        done
        exit 0
        ;;
    *)
        # Default to next
        CURRENT=$(( (CURRENT + 1) % TOTAL ))
        ;;
esac

# Save new index
echo "$CURRENT" > "$STATE_FILE"

# Get wallpaper path
WALLPAPER="${WALLPAPERS[$CURRENT]}"

# Start new swaybg first, then kill old one to avoid black flash
swaybg -i "$WALLPAPER" -m fill &
disown
sleep 0.15
pkill -o swaybg 2>/dev/null || true

# Show notification with wallpaper name
BASENAME=$(basename "$WALLPAPER")
notify-send "Wallpaper" "$BASENAME ($(($CURRENT + 1))/$TOTAL)" -t 1500
