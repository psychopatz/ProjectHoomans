"""Proof that Semantic Lab layout state persists and can be reset safely."""

from __future__ import annotations

import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class UIStatePersistenceTests(unittest.TestCase):
    def _wait_until(self, root: tk.Tk, predicate: object) -> None:
        deadline = time.monotonic() + 45.0
        while not predicate() and time.monotonic() < deadline:
            root.update()
            time.sleep(0.02)
        self.assertTrue(predicate(), "timed out waiting for Semantic Lab")

    def test_layout_preferences_persist_and_reset_without_scenario_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "ui-state.json"
            arguments = _parser().parse_args(["--ui-state", str(state_path)])

            root = tk.Tk()
            app = SemanticHarnessApp(root, arguments)
            try:
                self._wait_until(root, lambda: app.worker_ready)
                app._toggle_trace_panel()
                app._toggle_advanced_controls()
                app.toggle_simulation_workbench()
                app._save_ui_state()
            finally:
                app.close()

            root = tk.Tk()
            restored = SemanticHarnessApp(root, arguments)
            try:
                self._wait_until(root, lambda: restored.worker_ready)
                root.update_idletasks()
                self.assertFalse(restored.trace_panel_visible)
                self.assertFalse(restored.advanced_controls_visible)
                self.assertFalse(restored.workbench_expanded)
                restored.reset_layout_button.invoke()
                self.assertTrue(restored.trace_panel_visible)
                self.assertTrue(restored.advanced_controls_visible)
                self.assertTrue(restored.workbench_expanded)
            finally:
                restored.close()

            reset_arguments = _parser().parse_args(
                ["--ui-state", str(state_path), "--reset-ui-state"]
            )
            root = tk.Tk()
            reset = SemanticHarnessApp(root, reset_arguments)
            try:
                self._wait_until(root, lambda: reset.worker_ready)
                root.update_idletasks()
                self.assertTrue(reset.trace_panel_visible)
                self.assertTrue(reset.advanced_controls_visible)
                self.assertTrue(reset.workbench_expanded)
            finally:
                reset.close()


if __name__ == "__main__":
    unittest.main()
