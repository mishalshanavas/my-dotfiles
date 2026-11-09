#!/usr/bin/env python3
"""Show desktop apps in Fuzzel with one dot per existing Niri window."""

import json
import os
from pathlib import Path
import subprocess

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio

import niri_spawnjump as jump

# Fuzzel's width=40 uses wider character metrics than MonoLisa's space advance.
# Leave room for Fuzzel's end-of-line clipping reserve.
ROW_COLUMNS = 43


def matching(app, windows):
    ids = {app.get_id().removesuffix(".desktop").casefold()}
    wmclass = app.get_startup_wm_class()
    if wmclass:
        ids.add(wmclass.casefold())
    command = app.get_commandline()
    if command:
        try:
            ids.add(jump.infer_app_id(command).casefold())
        except (ValueError, jump.SpawnJumpError):
            pass
    return [w for w in windows if str(w.get("app_id", "")).casefold() in ids]


def rows(apps, windows):
    result = []
    for app in apps:
        name = app.get_display_name().replace("\n", " ").replace("\t", " ")
        dots = "●" * len(matching(app, windows))
        available = max(1, ROW_COLUMNS - len(dots) - 2)
        if len(name) > available:
            name = name[:available - 1] + "…"
        result.append(name + " " * max(2, ROW_COLUMNS - len(name) - len(dots)) + dots if dots else name)
    return result


def launch_new(app):
    actions = app.list_actions()
    action = next((a for a in actions if a in {"new-window", "NewWindow"}), None)
    if action:
        app.launch_action(action, None)
    else:
        app.launch([], None)


def main():
    client = jump.NiriClient()
    try:
        windows = client.windows()
    except jump.SpawnJumpError:
        windows = []
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "niri-app-menu.json"
    try:
        history = json.loads(cache.read_text())
        if not isinstance(history, dict):
            history = {}
    except (OSError, ValueError):
        history = {}
    apps = sorted((a for a in Gio.AppInfo.get_all() if a.should_show()),
                  key=lambda a: (-history.get(a.get_id(), 0), a.get_display_name().casefold(), a.get_id()))
    result = subprocess.run(["fuzzel", "--dmenu", "--index", "--match-mode=fzf", "--width=40",
                             "--override=key-bindings.execute-input=none",
                             "--override=key-bindings.custom-1=Shift+Return Shift+KP_Enter"],
                            input="\n".join(rows(apps, windows)) + "\n", text=True, capture_output=True)
    if result.returncode not in (0, 10) or not result.stdout.strip():
        return 0
    index = int(result.stdout.strip())
    app = apps[index]
    # Refresh after the menu closes: a window may have exited meanwhile.
    try:
        matches = matching(app, client.windows())
    except jump.SpawnJumpError:
        matches = []
    if result.returncode == 10:
        launch_new(app)
    elif matches:
        target = max(matches, key=lambda w: (w.get("is_focused", False),
                     (w.get("focus_timestamp") or {}).get("secs", 0),
                     (w.get("focus_timestamp") or {}).get("nanos", 0)))
        client.action("focus-window", "--id", str(target["id"]))
    else:
        app.launch([], None)
    history[app.get_id()] = history.get(app.get_id(), 0) + 1
    try:
        cache.parent.mkdir(parents=True, exist_ok=True)
        cache.write_text(json.dumps(history))
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
