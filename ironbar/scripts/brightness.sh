#!/bin/sh
backlight_path() {
    for dev in /sys/class/backlight/*; do
        [ -r "$dev/brightness" ]     || continue
        [ -r "$dev/max_brightness" ] || continue
        printf '%s\n' "$dev"
        return 0
    done
    return 1
}

read_int() {
    [ -r "$1" ] || return 1
    val=$(tr -cd '0-9' < "$1")
    [ -n "$val" ] || return 1
    printf '%s\n' "$val"
}

is_int() {
    case $1 in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

get_pct() {
    cur=$(read_int "$BL_PATH/brightness")
    max=$(read_int "$BL_PATH/max_brightness")
    if is_int "$cur" && is_int "$max" && [ "$max" -gt 0 ]; then
        printf '%s\n' "$(( (100 * cur + max / 2) / max ))"
        return 0
    fi
    return 1
}

render() {
    val=$(get_pct)

    if [ -z "$val" ]; then
        printf '  N/A\n'
        return
    fi

    if   [ "$val" -ge 75 ]; then icon=""
    elif [ "$val" -ge 40 ]; then icon=""
    elif [ "$val" -ge 10 ]; then icon=""
    else                         icon=""
    fi

    printf '%s  %s%%\n' "$icon" "$val"
}

BL_PATH=$(backlight_path)
if [ -z "$BL_PATH" ]; then
    printf '  N/A\n'
    exit 0
fi

render

command -v inotifywait >/dev/null 2>&1 || exit 0

# Run inotifywait without a subshell pipeline so render() runs in this process
# and can share state cleanly. We use a temp FIFO for this.
fifo=$(mktemp -u /tmp/.brightness_inotify_XXXXXX)
mkfifo "$fifo"
trap 'rm -f "$fifo"' EXIT INT TERM

inotifywait -m -e modify -e close_write "$BL_PATH/brightness" 2>/dev/null > "$fifo" &
inotify_pid=$!

while IFS= read -r _ < "$fifo"; do
    render
done

kill "$inotify_pid" 2>/dev/null || true