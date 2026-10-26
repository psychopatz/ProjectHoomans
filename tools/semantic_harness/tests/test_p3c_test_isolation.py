"""P3C GUI isolation and foreground-readiness regressions."""

from __future__ import annotations

import os
from pathlib import Path
import tempfile
import tkinter as tk
import unittest
from unittest.mock import patch

from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase
from tools.semantic_harness.ui.state import save as save_ui_state
from tools.semantic_harness.ui.state import state_path


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class P3CTestIsolationTests(SemanticLabGuiTestCase):
    def test_ordinary_gui_helper_ignores_default_remembered_save_state(self) -> None:
        with self.subTest(default_state="remembered SAVE"):
            with tempfile.TemporaryDirectory(
                prefix="projecthoomans-default-state-"
            ) as state_home, patch.dict(
                os.environ, {"XDG_STATE_HOME": state_home}
            ):
                repository = Path(__file__).resolve().parents[3]
                poisoned_default = state_path(repository, None)
                save_ui_state(
                    poisoned_default,
                    {
                        "active_source_kind": "SAVE",
                        "saved_world_save_path": "/tmp/real-sandbox-save.bin",
                        "saved_world_player_id": "char_real_player",
                        "saved_world_npc_id": "npc_real_target",
                    },
                )
                root = tk.Tk()
                app = self.make_gui_app(root)
                try:
                    self.wait_for_worker_ready(root, app)
                    self.assertFalse(app.save_backed_mode)
                    self.assertEqual(
                        app.source_snapshot_projection.get("metadata", {}).get(
                            "sourceKind", "FIXTURE"
                        ),
                        "FIXTURE",
                    )
                    self.assertNotEqual(app.ui_state_path, poisoned_default)
                finally:
                    self.close_gui_app(app, root)

    def test_explore_loading_does_not_make_foreground_app_busy(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        try:
            self.wait_for_worker_ready(root, app)
            self.assertFalse(app.busy)
            self.wait_for_explore_loaded(root, app)
            self.assertTrue(app.observatory.refresh())
            self.assertTrue(app.observatory.loading)
            self.assertFalse(app.busy)
            self.assertNotEqual(app.status_var.get(), "Working…")
            self.wait_for_explore_loaded(root, app)
        finally:
            self.close_gui_app(app, root)

if __name__ == "__main__":
    unittest.main()
