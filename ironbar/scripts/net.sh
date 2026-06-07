#!/bin/sh
net_status() {
    if ! command -v nmcli >/dev/null 2>&1; then
        printf '   Net\n'
        return
    fi

    # nmcli is colon-delimited in terse mode. Strip only the first two fields so
    # the connection name can still contain additional colons safely.
    result=$(nmcli -t -f TYPE,STATE,CONNECTION -e no dev 2>/dev/null \
        | awk -F: '
            function conn(line) {
                sub(/^[^:]*:[^:]*:/, "", line)
                return line
            }

            $1 == "wifi"     && $2 == "connected" && wifi == "" { wifi = conn($0) }
            $1 == "ethernet" && $2 == "connected" && eth  == "" { eth  = conn($0) }
            END { print wifi "\t" eth }
        ')

    wifi=${result%%	*}
    eth=${result#*	}

    if [ -n "$wifi" ]; then
        printf '  %s\n' "$wifi"
    elif [ -n "$eth" ]; then
        printf '  %s\n' "$eth"
    elif nmcli -t -f STATE -e no dev 2>/dev/null | grep -q '^connecting$'; then
        printf '  Connecting\n'
    else
        printf '  Offline\n'
    fi
}

net_status

# Use a FIFO so nmcli monitor output is readable in this process (not a subshell),
# meaning net_status's printf goes directly to ironbar's stdout as expected.
fifo=$(mktemp -u /tmp/.net_monitor_XXXXXX)
mkfifo "$fifo"
monitor_pid=""
trap 'rm -f "$fifo"; [ -n "$monitor_pid" ] && kill "$monitor_pid" 2>/dev/null' EXIT INT TERM

while true; do
    nmcli monitor 2>/dev/null > "$fifo" &
    monitor_pid=$!

    while IFS= read -r _line < "$fifo"; do
        net_status
    done

    # monitor exited (NM restarted etc.) — clean up and retry
    kill "$monitor_pid" 2>/dev/null
    wait "$monitor_pid" 2>/dev/null
    sleep 2
    net_status
done