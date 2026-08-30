#!/usr/bin/env bash

set -euo pipefail
umask 077

notify() {
    notify-send "Screen Recording" "$1" -t 4000 2>/dev/null || true
}

if ! command -v wf-recorder >/dev/null 2>&1; then
    notify "wf-recorder is not installed"
    exit 1
fi

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
state_dir="$runtime_dir/niri-screen-recorder"
pid_file="$state_dir/pid"
path_file="$state_dir/path"
lock_file="$state_dir/lock"
log_file="$state_dir/wf-recorder.log"
mkdir -p -- "$state_dir"

exec 9>"$lock_file"
flock -n 9 || exit 0

recorder_pid=""
if [[ -r "$pid_file" ]]; then
    recorder_pid=$(<"$pid_file")
fi

if [[ "$recorder_pid" =~ ^[0-9]+$ ]] \
    && [[ -r "/proc/$recorder_pid/comm" ]] \
    && [[ "$(<"/proc/$recorder_pid/comm")" == "wf-recorder" ]]; then
    recording_path=$(<"$path_file")
    kill -INT "$recorder_pid"

    # Give wf-recorder time to finalize the video container.
    for _ in {1..50}; do
        kill -0 "$recorder_pid" 2>/dev/null || break
        sleep 0.1
    done

    if kill -0 "$recorder_pid" 2>/dev/null; then
        notify "Stopping…"
        exit 0
    fi

    rm -f -- "$pid_file" "$path_file"
    notify "Saved to $recording_path"
    exit 0
fi

rm -f -- "$pid_file" "$path_file"

recordings_dir="$HOME/Videos/Recordings"
mkdir -p -- "$recordings_dir"
recording_path="$recordings_dir/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

wf-recorder -o eDP-1 -f "$recording_path" >>"$log_file" 2>&1 9>&- &
recorder_pid=$!
sleep 0.5

if ! kill -0 "$recorder_pid" 2>/dev/null; then
    wait "$recorder_pid" || true
    notify "Could not start; see $log_file"
    exit 1
fi

printf '%s\n' "$recorder_pid" >"$pid_file"
printf '%s\n' "$recording_path" >"$path_file"
notify "Started — press Super+Shift+Print to stop"
