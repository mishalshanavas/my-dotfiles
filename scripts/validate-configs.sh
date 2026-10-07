#!/usr/bin/env bash

set -euo pipefail

config_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$config_root"

status=0
report_failure() {
    printf 'FAIL: %s\n' "$1" >&2
    status=1
}

mapfile -d '' shell_files < <(
    find eww/scripts niri/scripts swaylock scripts -type f \
        \( -name '*.sh' -o -name 'fuzzel' \) -print0
)

for script in "${shell_files[@]}"; do
    bash -n "$script" || report_failure "shell syntax: $script"
done

python3 - <<'PY' || report_failure "Python syntax"
import ast
from pathlib import Path

for path in Path("niri/scripts").glob("*.py"):
    ast.parse(path.read_text(), filename=str(path))
PY

python3 -m unittest discover -s niri/scripts -p 'test_*.py' || report_failure "Python tests"

if command -v shellcheck >/dev/null 2>&1; then
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
    mapfile -d '' systemd_units < <(find systemd/user -maxdepth 1 -type f -name '*.service' -print0)
    systemd_output=$(mktemp)
    if systemd-analyze --user verify "${systemd_units[@]}" 2>"$systemd_output"; then
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

if command -v fuzzel >/dev/null 2>&1; then
    fuzzel --check-config --config=fuzzel/fuzzel.ini || report_failure "Fuzzel config"
fi

if command -v ghostty >/dev/null 2>&1; then
    ghostty +validate-config --config-file=ghostty/config.ghostty || report_failure "Ghostty config"
fi

python3 - <<'PY' || report_failure "INI config"
import configparser
from pathlib import Path

for name in ("networkmanager-dmenu/config.ini",):
    parser = configparser.RawConfigParser()
    with Path(name).open(encoding="utf-8") as stream:
        parser.read_file(stream)
PY

if command -v eww >/dev/null 2>&1 && eww ping >/dev/null 2>&1; then
    eww -c eww reload || report_failure "Eww config"
else
    printf 'SKIP: Eww daemon is not running\n'
fi

if (( status != 0 )); then
    exit "$status"
fi
printf 'All available configuration checks passed.\n'
