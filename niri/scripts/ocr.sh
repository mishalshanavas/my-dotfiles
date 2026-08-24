#!/usr/bin/env bash

set -euo pipefail
umask 077

notify() {
    notify-send "OCR" "$1" -t 5000 2>/dev/null || true
}

for command_name in grim slurp tesseract wl-copy; do
    command -v "$command_name" >/dev/null 2>&1 || {
        notify "$command_name is not installed"
        exit 1
    }
done

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
image=$(mktemp "$runtime_dir/niri-ocr.XXXXXX.png") || exit 1
trap 'rm -f -- "$image"' EXIT INT TERM

geometry=$(slurp) || exit 0
grim -g "$geometry" "$image" || {
    notify "Screenshot capture failed"
    exit 1
}

text=$(tesseract "$image" - 2>/dev/null | tr -d '\n' | head -c 200) || true
if [[ -z "$text" ]]; then
    notify "No text was recognized"
    exit 1
fi

printf '%s' "$text" | wl-copy
notify "$text"
