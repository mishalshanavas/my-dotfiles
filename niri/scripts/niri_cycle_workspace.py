#!/usr/bin/env python3
"""Wrap Super+Tab through occupied workspaces on the focused output."""

import json
import subprocess
import sys


def niri_json(command):
    return json.loads(subprocess.check_output(["niri", "msg", "--json", command]))


def main():
    direction = -1 if len(sys.argv) > 1 and sys.argv[1] == "previous" else 1
    workspaces = niri_json("workspaces")
    focused = next((ws for ws in workspaces if ws["is_focused"]), None)
    if focused is None:
        return

    occupied_ids = {window["workspace_id"] for window in niri_json("windows")}
    candidates = sorted(
        (ws for ws in workspaces
         if ws["output"] == focused["output"]
         and (ws["id"] in occupied_ids or ws["id"] == focused["id"])),
        key=lambda ws: ws["idx"],
    )
    if len(candidates) < 2:
        return

    current = next(i for i, ws in enumerate(candidates) if ws["id"] == focused["id"])
    target = candidates[(current + direction) % len(candidates)]
    subprocess.run(["niri", "msg", "action", "focus-workspace", str(target["idx"])], check=True)


if __name__ == "__main__":
    main()
