#!/usr/bin/env bash

set -euo pipefail

config_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$config_root"

status=0
report_failure() {
    printf 'FAIL: %s\n' "$1" >&2
    status=1
}

while IFS= read -r -d '' script; do
    bash -n "$script" || report_failure "shell syntax: $script"
done < <(find eww/scripts niri/scripts swaylock scripts -type f -name '*.sh' -print0)

python3 - <<'PY' || report_failure "Python syntax"
import ast
from pathlib import Path

for path in Path("niri/scripts").glob("*.py"):
    ast.parse(path.read_text(), filename=str(path))
PY

python3 -m unittest discover -s niri/scripts -p 'test_*.py' || report_failure "Python tests"

if command -v shellcheck >/dev/null 2>&1; then
    mapfile -d '' shell_files < <(find eww/scripts niri/scripts swaylock scripts -type f -name '*.sh' -print0)
    shellcheck "${shell_files[@]}" || report_failure "ShellCheck"
else
    printf 'SKIP: shellcheck is not installed\n'
fi

if command -v niri >/dev/null 2>&1; then
    niri validate -c niri/config.kdl || report_failure "Niri config"
else
    printf 'SKIP: niri is not installed\n'
fi

if command -v systemd-analyze >/dev/null 2>&1; then
    systemd_output=$(mktemp)
    if systemd-analyze --user verify systemd/user/niri-*.service 2>"$systemd_output"; then
        :
    elif grep -Ev '^(Failed to turn off SO_PASSRIGHTS|Failed to enable SO_PASSCRED)' "$systemd_output" | grep -q .; then
        cat "$systemd_output" >&2
        report_failure "systemd units"
    else
        printf 'SKIP: systemd verification is restricted by the sandbox\n'
    fi
    rm -f "$systemd_output"
else
    printf 'SKIP: systemd-analyze is not installed\n'
fi

if command -v eww >/dev/null 2>&1 && eww ping >/dev/null 2>&1; then
    eww -c eww reload || report_failure "Eww config"
else
    printf 'SKIP: Eww daemon is not running\n'
fi

if (( status != 0 )); then
    exit "$status"
fi
printf 'All available configuration checks passed.\n'
