"""S4 interaction checks for the existing Tk Semantic Lab surface."""

from __future__ import annotations

import os
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualSuggestionsS4Tests(unittest.TestCase):
    def test_existing_lab_renders_inspects_and_clicks_production_suggestions(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        def wait_until(predicate: object, timeout: float = 10.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            app.main_tabs.select(app.simulation_tab)
            app.input_var.set("Are you okay?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))

            self.assertEqual(len(app.suggestion_buttons), 5)
            self.assertEqual(
                str(app.suggestion_buttons[0].cget("state")), "normal"
            )
            self.assertEqual(
                str(app.suggestion_buttons[4].cget("state")), "disabled"
            )
            self.assertIn(
                "predicateTrace",
                app.suggestion_inspector.get("1.0", "end"),
            )

            app.click_suggestion(0)
            wait_until(lambda: not app.busy)
            transcript = app.transcript.get("1.0", "end")
            self.assertIn("PLAYER:", transcript)
            self.assertIn(
                "semantic_click_frame",
                app.suggestion_inspector.get("1.0", "end"),
            )

            follow_index = next(
                index
                for index, row in enumerate(app.suggestion_rows)
                if row.get("action") == "FOLLOW"
            )
            app.click_suggestion(follow_index)
            wait_until(lambda: not app.busy)
            self.assertIn("TOOL/ACTION:", app.transcript.get("1.0", "end"))
            self.assertIn("follow", app.transcript.get("1.0", "end").lower())

            app.language_var.set("TL")
            app.set_language()
            wait_until(lambda: not app.busy)
            app.input_var.set("Are you okay?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            self.assertIn(
                "Itanong ang kalagayan",
                [
                    str(button.cget("text"))
                    for button in app.suggestion_buttons
                ],
            )
        finally:
            app.close()
            root.update()


if __name__ == "__main__":
    unittest.main()
