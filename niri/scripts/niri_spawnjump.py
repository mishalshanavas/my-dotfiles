#!/usr/bin/env python3
"""Spawn, focus, cycle, or scratchpad-toggle Niri windows."""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time
from typing import Any, Sequence


class SpawnJumpError(RuntimeError):
    """An error suitable for presenting to the desktop user."""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Spawn or cycle matching application windows in Niri.",
        epilog="Run without arguments to print the focused window's app-id.",
    )
    parser.add_argument("command", nargs="?", help="command used to launch the application")
    parser.add_argument("app_id", nargs="?", help="exact app-id to match")
    parser.add_argument("-l", "--limit", type=int, default=1, help="spawn up to N matching windows (default: 1)")
    parser.add_argument("-b", "--backward", action="store_true", help="cycle backward")
    parser.add_argument("-w", "--workspace", action="store_true", help="match only the single focused workspace")
    parser.add_argument(
        "--active-workspaces", action="store_true", help="match visible workspaces on every output"
    )
    parser.add_argument("-p", "--pull", action="store_true", help="move a sole match to the focused workspace")
    parser.add_argument("-s", "--push", action="store_true", help="push a focused sole match away")
    parser.add_argument(
        "-t",
        "--scratch",
        nargs="?",
        const="",
        metavar="NAME",
        help="toggle a sole match through an adjacent workspace, or an optional named workspace",
    )
    parser.add_argument("--no_floats", action="store_true", help="ignore floating matches")
    parser.add_argument("--no_tiles", action="store_true", help="ignore tiled matches")
    parser.add_argument("--no_spawn", action="store_true", help="focus only; never launch")
    parser.add_argument("--always_spawn", action="store_true", help="always launch a new process")
    parser.add_argument(
        "-o",
        "--spawn_in_overview",
        action="store_true",
        help="always launch while the overview is open",
    )
    parser.add_argument(
        "--spawn-timeout",
        type=float,
        default=4.0,
        metavar="SECONDS",
        help="wait this long for a launched window to appear (default: 4)",
    )
    return parser


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.limit < 1:
        parser.error("--limit must be at least 1")
    if args.spawn_timeout < 0:
        parser.error("--spawn-timeout cannot be negative")
    if args.no_floats and args.no_tiles:
        parser.error("--no_floats and --no_tiles cannot be used together")
    if args.always_spawn and args.no_spawn:
        parser.error("--always_spawn and --no_spawn cannot be used together")
    if args.workspace and args.active_workspaces:
        parser.error("--workspace and --active-workspaces cannot be used together")
    if args.scratch is not None:
        args.pull = True
        args.push = True
        # A hidden scratchpad window must remain discoverable globally.
        args.workspace = False
        args.active_workspaces = False
    return args


def infer_app_id(command: str) -> str:
    words = shlex.split(command)
    if not words:
        raise SpawnJumpError("the launch command is empty")
    executable = Path(words[0]).name
    if executable == "flatpak" and "run" in words:
        after_run = words[words.index("run") + 1 :]
        app_candidates = [word for word in after_run if not word.startswith("-")]
        if app_candidates:
            return app_candidates[0]
    return executable


def notify_error(message: str) -> None:
    try:
        subprocess.run(
            ["notify-send", "Window shortcut failed", message],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except OSError:
        pass


class NiriClient:
    def _run(self, arguments: Sequence[str], *, json_output: bool = False) -> subprocess.CompletedProcess[str]:
        command = ["niri", "msg"]
        if json_output:
            command.append("--json")
        command.extend(arguments)
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=False)
        except FileNotFoundError as error:
            raise SpawnJumpError("niri is not installed") from error
        if result.returncode != 0:
            detail = result.stderr.strip() or result.stdout.strip() or f"exit status {result.returncode}"
            raise SpawnJumpError(f"Niri IPC failed: {detail}")
        return result

    def request(self, name: str) -> Any:
        result = self._run([name], json_output=True)
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise SpawnJumpError(f"Niri returned invalid JSON for {name}") from error

    def action(self, name: str, *arguments: str) -> None:
        self._run(["action", name, *arguments])

    def windows(self) -> list[dict[str, Any]]:
        value = self.request("windows")
        if not isinstance(value, list):
            raise SpawnJumpError("Niri returned an unexpected windows response")
        return value

    def workspaces(self) -> list[dict[str, Any]]:
        value = self.request("workspaces")
        if not isinstance(value, list):
            raise SpawnJumpError("Niri returned an unexpected workspaces response")
        return value

    def focused_window(self) -> dict[str, Any] | None:
        value = self.request("focused-window")
        if value is not None and not isinstance(value, dict):
            raise SpawnJumpError("Niri returned an unexpected focused-window response")
        return value

    def overview_is_open(self) -> bool:
        value = self.request("overview-state")
        return isinstance(value, dict) and bool(value.get("is_open", False))


def focused_workspace(workspaces: Sequence[dict[str, Any]]) -> dict[str, Any]:
    try:
        return next(workspace for workspace in workspaces if workspace.get("is_focused"))
    except StopIteration as error:
        raise SpawnJumpError("Niri has no focused workspace") from error


def workspace_by_id(workspaces: Sequence[dict[str, Any]]) -> dict[int, dict[str, Any]]:
    return {int(workspace["id"]): workspace for workspace in workspaces if "id" in workspace}


def matching_windows(
    windows: Sequence[dict[str, Any]],
    workspaces: Sequence[dict[str, Any]],
    app_id: str,
    args: argparse.Namespace,
) -> list[dict[str, Any]]:
    matches = [window for window in windows if str(window.get("app_id", "")).casefold() == app_id.casefold()]
    if args.workspace:
        focused_id = int(focused_workspace(workspaces)["id"])
        matches = [window for window in matches if window.get("workspace_id") == focused_id]
    elif args.active_workspaces:
        active_ids = {workspace.get("id") for workspace in workspaces if workspace.get("is_active")}
        matches = [window for window in matches if window.get("workspace_id") in active_ids]
    if args.no_floats:
        matches = [window for window in matches if not window.get("is_floating", False)]
    if args.no_tiles:
        matches = [window for window in matches if window.get("is_floating", False)]
    return matches


def window_sort_key(window: dict[str, Any], workspaces: Sequence[dict[str, Any]]) -> tuple[Any, ...]:
    workspace = workspace_by_id(workspaces).get(int(window.get("workspace_id", -1)), {})
    output = str(workspace.get("output") or "")
    workspace_index = int(workspace.get("idx", 0))
    layout = window.get("layout") or {}
    position = layout.get("pos_in_scrolling_layout")
    if window.get("is_floating") or not isinstance(position, (list, tuple)) or len(position) != 2:
        column, row = -1, -1
    else:
        column, row = int(position[0]), int(position[1])
    return output, workspace_index, column, row, int(window.get("pid") or -1), int(window["id"])


def focus_cycle(
    client: NiriClient,
    matches: Sequence[dict[str, Any]],
    workspaces: Sequence[dict[str, Any]],
    focused: dict[str, Any] | None,
    *,
    backward: bool,
) -> None:
    ordered = sorted(matches, key=lambda window: window_sort_key(window, workspaces))
    if not ordered:
        return
    focused_id = focused.get("id") if focused else None
    ids = [window["id"] for window in ordered]
    if focused_id in ids:
        offset = -1 if backward else 1
        target_id = ids[(ids.index(focused_id) + offset) % len(ids)]
    else:
        target_id = ids[-1] if backward else ids[0]
    client.action("focus-window", "--id", str(target_id))


def move_to_focused_workspace(
    client: NiriClient,
    window: dict[str, Any],
    workspaces: Sequence[dict[str, Any]],
) -> None:
    destination = focused_workspace(workspaces)
    if window.get("workspace_id") == destination.get("id"):
        return
    source = workspace_by_id(workspaces).get(int(window.get("workspace_id", -1)), {})
    if source.get("output") != destination.get("output") and destination.get("output"):
        # Moving to an output places the window on that output's active
        # workspace, which is the focused workspace for the focused output.
        client.action(
            "move-window-to-monitor",
            "--id",
            str(window["id"]),
            str(destination["output"]),
        )
    else:
        # Workspace indexes are unambiguous here because source and destination
        # are on the same output.
        client.action(
            "move-window-to-workspace",
            "--window-id",
            str(window["id"]),
            "--focus",
            "false",
            str(destination["idx"]),
        )


def pull_window(client: NiriClient, window: dict[str, Any], workspaces: Sequence[dict[str, Any]]) -> None:
    move_to_focused_workspace(client, window, workspaces)
    client.action("focus-window", "--id", str(window["id"]))


def push_window(client: NiriClient, window: dict[str, Any], scratchpad: str | None) -> None:
    if scratchpad is not None and scratchpad != "":
        client.action(
            "move-window-to-workspace",
            "--window-id",
            str(window["id"]),
            "--focus",
            "false",
            scratchpad,
        )
    elif window.get("is_floating") or scratchpad is not None:
        client.action("move-window-to-workspace-down", "--focus", "false")
    else:
        client.action("move-column-to-last")


def launch(command: str) -> subprocess.Popen[bytes]:
    words = shlex.split(command)
    if not words:
        raise SpawnJumpError("the launch command is empty")
    try:
        return subprocess.Popen(
            words,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
            start_new_session=True,
        )
    except FileNotFoundError as error:
        raise SpawnJumpError(f"cannot find launch command: {words[0]}") from error
    except OSError as error:
        raise SpawnJumpError(f"could not launch {words[0]}: {error}") from error


def wait_for_window(
    client: NiriClient,
    app_id: str,
    args: argparse.Namespace,
    previous_count: int,
    process: subprocess.Popen[bytes],
) -> bool:
    deadline = time.monotonic() + args.spawn_timeout
    while time.monotonic() < deadline:
        if process.poll() not in (None, 0):
            raise SpawnJumpError(f"{shlex.split(args.command)[0]} exited before opening a window")
        time.sleep(0.05)
        workspaces = client.workspaces()
        matches = matching_windows(client.windows(), workspaces, app_id, args)
        if len(matches) > previous_count:
            return True
    return False


def invocation_lock(scope_key: str):
    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    digest = hashlib.sha256(scope_key.casefold().encode()).hexdigest()[:16]
    lock_path = runtime_dir / f"niri-spawnjump-{digest}.lock"
    lock_file = lock_path.open("a+", encoding="utf-8")
    os.chmod(lock_path, 0o600)
    fcntl.flock(lock_file, fcntl.LOCK_EX)
    return lock_file


def pending_spawn_is_active(lock_file, current_count: int) -> bool:
    lock_file.seek(0)
    try:
        pending = json.loads(lock_file.read() or "null")
    except json.JSONDecodeError:
        pending = None
    if not isinstance(pending, dict):
        return False
    if current_count > int(pending.get("previous_count", -1)):
        clear_pending_spawn(lock_file)
        return False
    if time.time() >= float(pending.get("expires_at", 0)):
        clear_pending_spawn(lock_file)
        return False
    return True


def record_pending_spawn(lock_file, previous_count: int, timeout: float) -> None:
    lock_file.seek(0)
    lock_file.truncate()
    json.dump(
        {"previous_count": previous_count, "expires_at": time.time() + max(timeout, 12.0)},
        lock_file,
        separators=(",", ":"),
    )
    lock_file.flush()


def clear_pending_spawn(lock_file) -> None:
    lock_file.seek(0)
    lock_file.truncate()
    lock_file.flush()


def scope_key(app_id: str, args: argparse.Namespace, workspaces: Sequence[dict[str, Any]]) -> str:
    if args.workspace:
        scope = f"focused:{focused_workspace(workspaces)['id']}"
    elif args.active_workspaces:
        active_ids = sorted(int(workspace["id"]) for workspace in workspaces if workspace.get("is_active"))
        scope = "active:" + ",".join(map(str, active_ids))
    else:
        scope = "global"
    return f"{app_id.casefold()}:{scope}"


def inspect_app_ids(client: NiriClient) -> int:
    last: str | None = None
    try:
        while True:
            focused = client.focused_window()
            current = str(focused.get("app_id")) if focused else "no app-id available"
            if current != last:
                print(f"app-id: {current}", flush=True)
                last = current
            time.sleep(0.25)
    except KeyboardInterrupt:
        return 0


def run(args: argparse.Namespace, client: NiriClient | None = None) -> int:
    client = client or NiriClient()
    if args.command is None and args.app_id is None:
        return inspect_app_ids(client)
    if args.command is None:
        raise SpawnJumpError("an app-id requires a launch command")

    app_id = args.app_id or infer_app_id(args.command)
    initial_workspaces = client.workspaces()
    with invocation_lock(scope_key(app_id, args, initial_workspaces)) as lock_file:
        workspaces = client.workspaces()
        windows = client.windows()
        focused = next((window for window in windows if window.get("is_focused")), None)
        matches = matching_windows(windows, workspaces, app_id, args)

        always_spawn = args.always_spawn or (args.spawn_in_overview and client.overview_is_open())
        if always_spawn or len(matches) < args.limit:
            if not args.no_spawn:
                if not always_spawn and pending_spawn_is_active(lock_file, len(matches)):
                    return 0
                process = launch(args.command)
                if not always_spawn:
                    record_pending_spawn(lock_file, len(matches), args.spawn_timeout)
                try:
                    appeared = wait_for_window(client, app_id, args, len(matches), process)
                except Exception:
                    clear_pending_spawn(lock_file)
                    raise
                if appeared:
                    clear_pending_spawn(lock_file)
            return 0

        if len(matches) == 1:
            target = matches[0]
            if target.get("is_focused") and args.push:
                push_window(client, target, args.scratch)
            elif args.pull:
                pull_window(client, target, workspaces)
            else:
                client.action("focus-window", "--id", str(target["id"]))
            return 0

        focus_cycle(client, matches, workspaces, focused, backward=args.backward)
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    try:
        return run(parse_args(argv))
    except (SpawnJumpError, KeyError, TypeError, ValueError, OSError) as error:
        message = str(error) or error.__class__.__name__
        print(f"niri_spawnjump: {message}", file=sys.stderr)
        notify_error(message)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
