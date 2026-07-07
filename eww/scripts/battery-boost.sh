#!/usr/bin/env bash
# Battery boost easter egg — each tap stacks +3%, reverts 5s after last tap
# Counter file tracks tap count; PID file manages the deferred revert timer

uid=$(id -u)
counter_file="/tmp/battery-boost-${uid}"
pid_file="/tmp/battery-boost-pid-${uid}"

# ── Kill any pending revert timer (we'll start a fresh one) ──
if [ -f "$pid_file" ]; then
    kill "$(cat "$pid_file")" 2>/dev/null
    rm -f "$pid_file"
fi

# ── Increment tap counter ────────────────────────────────────
tap_count=0
if [ -f "$counter_file" ]; then
    tap_count=$(cat "$counter_file" 2>/dev/null)
    tap_count=$((tap_count))
fi
tap_count=$((tap_count + 1))
echo "$tap_count" > "$counter_file"

# ── Calculate boosted display value ──────────────────────────
boost_pct=$((tap_count * 3))

# Get current eww battery value to extract real percentage
current=$(eww get battery 2>/dev/null)
pct=$(echo "$current" | grep -o '[0-9]\+' | head -1)

# Fallback to upower if eww parse fails
if [ -z "$pct" ]; then
    bat_dev=$(upower -e 2>/dev/null | awk '/battery/ {print; exit}')
    if [ -n "$bat_dev" ]; then
        pct=$(upower -i "$bat_dev" 2>/dev/null | awk -F': *' '/percentage:/ {pct=$2; gsub(/%/, "", pct); gsub(/\.[0-9]*/, "", pct); print pct}')
    fi
    [ -z "$pct" ] && pct=50
fi

boosted=$((pct + boost_pct))
[ "$boosted" -gt 100 ] && boosted=100

eww update battery=" $boosted%"

# ── Background: revert after 5s of inactivity ────────────────
(
    echo $$ > "$pid_file"
    sleep 5
    # Only revert if we're still the active timer (no newer tap replaced us)
    if [ -f "$pid_file" ] && [ "$(cat "$pid_file")" = "$$" ]; then
        rm -f "$counter_file" "$pid_file"

        # Restore real battery reading
        bat_dev=$(upower -e 2>/dev/null | awk '/battery/ {print; exit}')
        if [ -n "$bat_dev" ]; then
            info=$(upower -i "$bat_dev" 2>/dev/null | awk -F': *' '
                /^[[:space:]]*state:/      { state = $2 }
                /^[[:space:]]*percentage:/ { pct = $2; gsub(/%/, "", pct); gsub(/\.[0-9]*/, "", pct) }
                END { if (state == "") state = "unknown"; print state "|" pct }
            ')
            state_raw=${info%%|*}
            real_pct=${info#*|}

            case "$state_raw" in
                charging|fully-charged|pending-charge) icon='' ;;
                *)  if [ -n "$real_pct" ] && [ "$real_pct" -ge 90 ]; then icon=''
                    elif [ -n "$real_pct" ] && [ "$real_pct" -ge 70 ]; then icon=''
                    elif [ -n "$real_pct" ] && [ "$real_pct" -ge 50 ]; then icon=''
                    elif [ -n "$real_pct" ] && [ "$real_pct" -ge 20 ]; then icon=''
                    else icon=''
                    fi ;;
            esac

            eww update battery="$icon $real_pct%"
        fi
    fi
) &

