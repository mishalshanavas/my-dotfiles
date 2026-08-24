#!/usr/bin/env python3

import tempfile
import time
import unittest

import niri_spawnjump as spawnjump


WORKSPACES = [
    {"id": 101, "idx": 2, "output": "eDP-1", "is_active": True, "is_focused": True},
    {"id": 205, "idx": 1, "output": "HDMI-A-1", "is_active": True, "is_focused": False},
    {"id": 309, "idx": 3, "output": "eDP-1", "is_active": False, "is_focused": False},
]


def window(window_id, workspace_id, *, focused=False, floating=False, column=0, row=0):
    return {
        "id": window_id,
        "app_id": "Test.App",
        "workspace_id": workspace_id,
        "is_focused": focused,
        "is_floating": floating,
        "pid": window_id + 1000,
        "layout": {"pos_in_scrolling_layout": None if floating else [column, row]},
    }


class FakeClient:
    def __init__(self):
        self.actions = []

    def action(self, name, *arguments):
        self.actions.append((name, *arguments))

class SpawnJumpTests(unittest.TestCase):
    def test_workspace_scope_means_only_focused_workspace(self):
        args = spawnjump.parse_args(["test", "Test.App", "--workspace"])
        windows = [window(1, 101), window(2, 205), window(3, 309)]
        self.assertEqual([item["id"] for item in spawnjump.matching_windows(windows, WORKSPACES, "test.app", args)], [1])

    def test_active_scope_includes_visible_workspace_on_each_output(self):
        args = spawnjump.parse_args(["test", "Test.App", "--active-workspaces"])
        windows = [window(1, 101), window(2, 205), window(3, 309)]
        self.assertEqual(
            [item["id"] for item in spawnjump.matching_windows(windows, WORKSPACES, "Test.App", args)],
            [1, 2],
        )

    def test_cycle_uses_workspace_index_and_layout_position(self):
        client = FakeClient()
        windows = [window(1, 101, focused=True, column=1), window(2, 101, column=2), window(3, 101, column=3)]
        spawnjump.focus_cycle(client, windows, WORKSPACES, windows[0], backward=False)
        self.assertEqual(client.actions, [("focus-window", "--id", "2")])

    def test_cycle_without_focused_match_never_uses_sentinel_id(self):
        client = FakeClient()
        windows = [window(7, 101, column=1), window(8, 101, column=2)]
        spawnjump.focus_cycle(client, windows, WORKSPACES, None, backward=False)
        self.assertEqual(client.actions, [("focus-window", "--id", "7")])

    def test_pull_across_outputs_targets_focused_output(self):
        client = FakeClient()
        target = window(9, 205, floating=True)
        spawnjump.pull_window(client, target, WORKSPACES)
        self.assertEqual(
            client.actions,
            [
                ("move-window-to-monitor", "--id", "9", "eDP-1"),
                ("focus-window", "--id", "9"),
            ],
        )

    def test_pull_on_same_output_uses_workspace_index(self):
        client = FakeClient()
        target = window(9, 309, floating=True)
        spawnjump.pull_window(client, target, WORKSPACES)
        self.assertEqual(
            client.actions,
            [
                ("move-window-to-workspace", "--window-id", "9", "--focus", "false", "2"),
                ("focus-window", "--id", "9"),
            ],
        )

    def test_scratchpad_push_uses_named_workspace_without_following(self):
        client = FakeClient()
        spawnjump.push_window(client, window(4, 101, focused=True, floating=True), "scratchpad")
        self.assertEqual(
            client.actions,
            [("move-window-to-workspace", "--window-id", "4", "--focus", "false", "scratchpad")],
        )

    def test_unnamed_scratchpad_push_uses_adjacent_dynamic_workspace(self):
        client = FakeClient()
        spawnjump.push_window(client, window(4, 101, focused=True, floating=True), "")
        self.assertEqual(client.actions, [("move-window-to-workspace-down", "--focus", "false")])

    def test_scratch_flag_enables_global_push_pull_mode(self):
        args = spawnjump.parse_args(["test", "Test.App", "--scratch"])
        self.assertEqual(args.scratch, "")
        self.assertTrue(args.pull)
        self.assertTrue(args.push)
        self.assertFalse(args.workspace)

    def test_app_id_inference_uses_executable_or_flatpak_id(self):
        self.assertEqual(spawnjump.infer_app_id("ghostty --class=test"), "ghostty")
        self.assertEqual(spawnjump.infer_app_id("flatpak run --branch=stable org.example.App"), "org.example.App")

    def test_pending_spawn_blocks_until_count_changes_or_expiry(self):
        with tempfile.TemporaryFile(mode="w+") as lock_file:
            spawnjump.record_pending_spawn(lock_file, 0, 1)
            self.assertTrue(spawnjump.pending_spawn_is_active(lock_file, 0))
            self.assertFalse(spawnjump.pending_spawn_is_active(lock_file, 1))

            lock_file.seek(0)
            lock_file.truncate()
            lock_file.write('{"previous_count":1,"expires_at":%s}' % (time.time() - 1))
            lock_file.flush()
            self.assertFalse(spawnjump.pending_spawn_is_active(lock_file, 1))


if __name__ == "__main__":
    unittest.main()
