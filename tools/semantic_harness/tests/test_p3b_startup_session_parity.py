"""P3B real-worker Tk/Xvfb lifecycle acceptance tests."""

from __future__ import annotations

from hashlib import sha256
import json
import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)
PLAYER_UUID = "char_1791957489838_240087"
NPC_ID = "npcBarneyYamamoto_2OXA"
OVERRIDE_NPC_ID = "npcJordanMcLane_0LBN"


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class P3BStartupSessionParityTests(unittest.TestCase):
    def _wait_until(
        self,
        root: tk.Tk,
        predicate: object,
        message: str,
        timeout: float = 60.0,
    ) -> None:
        deadline = time.monotonic() + timeout
        while not predicate() and time.monotonic() < deadline:
            root.update()
            time.sleep(0.02)
        self.assertTrue(predicate(), message)

    def _arguments(self, state_path: Path, *extra: str):
        return _parser().parse_args(
            ["--gui", "--ui-state", str(state_path), *extra]
        )

    @staticmethod
    def _close(app: SemanticHarnessApp) -> None:
        try:
            app.close()
        except tk.TclError:
            pass

    def test_fresh_start_has_no_diagnostic_response_buttons_and_explore_autoloads(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "ui-state.json"
            root = tk.Tk()
            app = SemanticHarnessApp(
                root,
                self._arguments(state_path, "--reset-ui-state"),
            )
            try:
                self._wait_until(
                    root,
                    lambda: app.worker_ready,
                    "timed out waiting for fresh production worker readiness",
                )
                self._wait_until(
                    root,
                    lambda: len(app.observatory.pools.get_children()) > 0,
                    "timed out waiting for automatic Explore catalog page",
                )
                self.assertLessEqual(
                    len(app.observatory.pools.get_children()), 64
                )
                self.assertEqual(
                    app.suggestion_primary_projection.get("schema"),
                    "semantic.native_conversation_view.v1",
                )
                self.assertEqual(app.suggestion_rows, [])
                self.assertEqual(
                    sum(
                        button.winfo_ismapped()
                        for button in app.suggestion_buttons
                    ),
                    0,
                )
                self.assertEqual(
                    app.suggestion_status.cget("text"),
                    "No conversation open · Response Channel has 0 native rows",
                )
                inspector = app.suggestion_inspector.get("1.0", "end")
                self.assertIn("diagnosticProjection", inspector)
                self.assertIn("visualRows", inspector)
                self.assertNotIn(
                    "Check in with them",
                    [str(button.cget("text")) for button in app.suggestion_buttons],
                )
            finally:
                self._close(app)

    def test_open_conversation_response_channel_matches_native_presentation(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "ui-state.json"
            root = tk.Tk()
            app = SemanticHarnessApp(
                root,
                self._arguments(state_path, "--reset-ui-state"),
            )
            try:
                self._wait_until(
                    root,
                    lambda: app.worker_ready,
                    "timed out waiting for production worker readiness",
                )
                app.main_tabs.select(app.simulation_tab)
                app.open_conversation_button.invoke()
                self._wait_until(
                    root,
                    lambda: (
                        not app.busy
                        and app.suggestion_primary_projection.get("schema")
                        == "semantic.native_conversation_view.v1"
                        and bool(app.last_response)
                    ),
                    "timed out waiting for native conversation presentation",
                )
                presentation = app.last_response["conversationPresentation"]
                native_rows = presentation["responseChannel"]["rows"]
                expected = [
                    (
                        str(row["id"]),
                        str(row.get("text") or row["id"]),
                        row.get("enabled") is True,
                        row.get("semanticFrame") or row.get("frame"),
                    )
                    for row in native_rows
                ]
                actual = [
                    (
                        str(row["id"]),
                        str(row["display"]["label"]),
                        row.get("enabled") is True,
                        row.get("semanticFrame") or row.get("frame"),
                    )
                    for row in app.suggestion_rows
                ]
                self.assertEqual(actual, expected)
                visible_buttons = [
                    button
                    for button in app.suggestion_buttons
                    if button.winfo_ismapped()
                ]
                self.assertEqual(len(visible_buttons), len(expected))
                self.assertEqual(
                    [str(button.cget("text")) for button in visible_buttons],
                    [row[1] for row in expected],
                )
                self.assertEqual(
                    [str(button.cget("state")) == "normal" for button in visible_buttons],
                    [row[2] for row in expected],
                )
            finally:
                self._close(app)

    @unittest.skipUnless(REAL_SAVE.is_file(), "real local save is unavailable")
    def test_save_pair_survives_worker_restart_and_lab_recreation(self) -> None:
        source_before = sha256(REAL_SAVE.read_bytes()).digest()
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "ui-state.json"
            explicit = self._arguments(
                state_path,
                "--reset-ui-state",
                "--load-saved-pair",
                "--save",
                str(REAL_SAVE),
                "--player",
                PLAYER_UUID,
                "--npc",
                NPC_ID,
            )
            root = tk.Tk()
            app = SemanticHarnessApp(root, explicit)
            try:
                self._wait_until(
                    root,
                    lambda: (
                        not app.busy
                        and app.source_snapshot_projection.get("metadata", {}).get(
                            "sourceKind"
                        )
                        == "SAVE"
                    ),
                    "timed out loading explicit saved pair",
                )
                self.assertTrue(app.save_backed_mode)
                self.assertEqual(app.scenario["npc"]["npcID"], NPC_ID)
                app.restart()
                self._wait_until(
                    root,
                    lambda: (
                        not app.busy
                        and app.source_snapshot_projection.get("metadata", {}).get(
                            "sourceKind"
                        )
                        == "SAVE"
                    ),
                    "timed out restarting the imported saved source",
                )
                self.assertEqual(app.scenario["npc"]["npcID"], NPC_ID)
                self.assertEqual(
                    app.source_snapshot_projection["metadata"]["savePath"],
                    str(REAL_SAVE),
                )
            finally:
                self._close(app)

            self.assertEqual(sha256(REAL_SAVE.read_bytes()).digest(), source_before)
            persisted = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(persisted["active_source_kind"], "SAVE")
            self.assertEqual(persisted["saved_world_save_path"], str(REAL_SAVE))
            self.assertEqual(persisted["saved_world_player_id"], PLAYER_UUID)
            self.assertEqual(persisted["saved_world_npc_id"], NPC_ID)

            root = tk.Tk()
            restored = SemanticHarnessApp(
                root,
                self._arguments(state_path),
            )
            try:
                self._wait_until(
                    root,
                    lambda: (
                        not restored.busy
                        and restored.source_snapshot_projection.get(
                            "metadata", {}
                        ).get("sourceKind")
                        == "SAVE"
                    ),
                    "timed out restoring the remembered saved pair",
                )
                self.assertTrue(restored.save_backed_mode)
                self.assertEqual(restored.scenario["npc"]["npcID"], NPC_ID)
                self.assertIn("Source SAVE", restored.simulation_context_var.get())
                self.assertIn("Save: 2026-10-14_13-57-03", restored.simulation_context_var.get())
                self.assertIn(
                    "Restoring saved target",
                    restored.transcript.get("1.0", "end"),
                )
            finally:
                self._close(restored)

    @unittest.skipUnless(REAL_SAVE.is_file(), "real local save is unavailable")
    def test_invalid_reset_and_explicit_saved_source_precedence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "ui-state.json"
            state_path.write_text(
                json.dumps(
                    {
                        "active_source_kind": "SAVE",
                        "saved_world_save_path": str(
                            Path(directory) / "missing-global-mod-data.bin"
                        ),
                        "saved_world_player_id": PLAYER_UUID,
                        "saved_world_npc_id": NPC_ID,
                    }
                ),
                encoding="utf-8",
            )
            root = tk.Tk()
            invalid = SemanticHarnessApp(root, self._arguments(state_path))
            try:
                self._wait_until(
                    root,
                    lambda: (
                        not invalid.busy
                        and invalid._ui_state.get("active_source_kind")
                        == "FIXTURE"
                    ),
                    "timed out applying invalid remembered-source fallback",
                )
                self.assertFalse(invalid.save_backed_mode)
                transcript = invalid.transcript.get("1.0", "end")
                self.assertEqual(
                    transcript.count("Remembered SAVE target could not be restored"),
                    1,
                )
                self.assertIn("Open World Browser", transcript)
                self.assertIn("Source FIXTURE", invalid.simulation_context_var.get())
            finally:
                self._close(invalid)

            valid_remembered = {
                "active_source_kind": "SAVE",
                "saved_world_save_path": str(REAL_SAVE),
                "saved_world_player_id": PLAYER_UUID,
                "saved_world_npc_id": NPC_ID,
            }
            state_path.write_text(json.dumps(valid_remembered), encoding="utf-8")
            root = tk.Tk()
            reset = SemanticHarnessApp(
                root,
                self._arguments(state_path, "--reset-ui-state"),
            )
            try:
                self._wait_until(
                    root,
                    lambda: reset.worker_ready,
                    "timed out starting clean fixture mode",
                )
                self.assertFalse(reset.save_backed_mode)
                self.assertIn("Source FIXTURE", reset.simulation_context_var.get())
                self.assertNotIn(
                    "Restoring saved target",
                    reset.transcript.get("1.0", "end"),
                )
            finally:
                self._close(reset)

            state_path.write_text(json.dumps(valid_remembered), encoding="utf-8")
            root = tk.Tk()
            explicit = SemanticHarnessApp(
                root,
                self._arguments(
                    state_path,
                    "--load-saved-pair",
                    "--save",
                    str(REAL_SAVE),
                    "--player",
                    PLAYER_UUID,
                    "--npc",
                    OVERRIDE_NPC_ID,
                ),
            )
            try:
                self._wait_until(
                    root,
                    lambda: (
                        not explicit.busy
                        and explicit.source_snapshot_projection.get(
                            "metadata", {}
                        ).get("sourceKind")
                        == "SAVE"
                    ),
                    "timed out applying explicit CLI saved-source override",
                )
                self.assertEqual(
                    explicit.scenario["npc"]["npcID"], OVERRIDE_NPC_ID
                )
            finally:
                self._close(explicit)
            persisted = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(persisted["active_source_kind"], "SAVE")
            self.assertEqual(persisted["saved_world_npc_id"], OVERRIDE_NPC_ID)


if __name__ == "__main__":
    unittest.main()
