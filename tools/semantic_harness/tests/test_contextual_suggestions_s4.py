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
            app.input_var.set("hello")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))

            self.assertEqual(len(app.suggestion_buttons), 5)
            self.assertEqual(
                str(app.suggestion_buttons[0].cget("state")), "normal"
            )
            self.assertIn(
                "Thank them",
                [
                    str(button.cget("text"))
                    for button in app.suggestion_buttons
                ],
            )
            self.assertIn(
                "Say you're doing fine",
                [
                    str(button.cget("text"))
                    for button in app.suggestion_buttons
                ],
            )
            self.assertEqual(
                str(app.suggestion_buttons[4].cget("state")), "disabled"
            )
            self.assertFalse(app.suggestion_buttons[4].winfo_ismapped())
            self.assertEqual(app.suggestion_group_box.get(), "Current conversation branch")
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

    def test_whats_up_gui_click_enters_real_registry_branch(self) -> None:
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
            app.input_var.set("whats up")
            app.submit()
            wait_until(
                lambda: not app.busy
                and any(
                    row.get("id") == "conversation.whats_up"
                    for row in app.suggestion_rows
                )
            )
            self.assertIn(
                "Ask what's up",
                [str(button.cget("text")) for button in app.suggestion_buttons],
            )

            root_index = next(
                index
                for index, row in enumerate(app.suggestion_rows)
                if row.get("id") == "conversation.whats_up"
            )
            app.click_suggestion(root_index)
            wait_until(
                lambda: not app.busy
                and any(
                    "What kind of movement?" in str(button.cget("text"))
                    for button in app.suggestion_buttons
                )
            )
            self.assertIn(
                "There's been movement around the neighborhood today.",
                app.transcript.get("1.0", "end"),
            )
            self.assertIn(
                "conversationBlock",
                app.suggestion_inspector.get("1.0", "end"),
            )
            detail_index = next(
                index
                for index, row in enumerate(app.suggestion_rows)
                if row.get("id", "").endswith(":detail")
            )
            app.click_suggestion(detail_index)
            wait_until(
                lambda: not app.busy
                and any(
                    "I can help check the area" in str(button.cget("text"))
                    for button in app.suggestion_buttons
                )
            )
            self.assertIn("Mostly tracks", app.transcript.get("1.0", "end"))
        finally:
            app.close()
            root.update()

    def test_npc_profile_combobox_reconfigures_worker_capabilities(self) -> None:
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
            app.npc_profile_var.set("Neutral NPC")
            app._on_npc_profile()
            wait_until(
                lambda: not app.busy
                and app.scenario["npc"]["actorAuthority"]["eligible"] is False
            )
            self.assertEqual(app.scenario["runtime"]["semanticLabProfile"], "neutral")
            self.assertEqual(
                app.npc_profile_box.get(),
                "Neutral NPC",
            )

            app.input_var.set("hello")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            self.assertNotIn(
                "Owned companion actions",
                [str(value) for value in app.suggestion_group_box["values"]],
            )
            self.assertFalse(
                any(row.get("action") == "FOLLOW" for row in app.suggestion_rows)
            )
        finally:
            app.close()
            root.update()

    def test_simulation_layout_keeps_runtime_controls_visible_without_maximizing(self) -> None:
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
            root.geometry("1080x700")
            app.main_tabs.select(app.simulation_tab)
            wait_until(lambda: app.worker_ready)
            root.update_idletasks()

            for widget in (
                app.language_box,
                app.npc_profile_box,
                app.send_button,
                app.status_label,
            ):
                self.assertTrue(widget.winfo_ismapped())

            # Root semantic suggestions are intentionally visible before the
            # first typed turn, so this is a populated baseline rather than a
            # blank placeholder panel.
            initial_panel_height = app.suggestion_frame.winfo_height()
            app.input_var.set("whats up")
            app.submit()
            wait_until(
                lambda: not app.busy
                and any(
                    row.get("id") == "conversation.whats_up"
                    for row in app.suggestion_rows
                )
            )
            root.update_idletasks()

            self.assertGreaterEqual(
                app.suggestion_frame.winfo_height(), initial_panel_height
            )
            self.assertGreater(app.send_button.winfo_y(), app.suggestion_frame.winfo_y())
            pane_right = app.transcript.winfo_rootx() + app.transcript.winfo_width()
            for button in (
                app.reset_button,
                app.load_button,
                app.settings_button,
                app.preview_button,
                app.save_button,
                app.snapshot_button,
                app.restart_button,
            ):
                self.assertLessEqual(
                    button.winfo_rootx() + button.winfo_width(),
                    pane_right,
                )
            self.assertLess(
                app.npc_profile_box.winfo_x() + app.npc_profile_box.winfo_width(),
                app.transcript.winfo_rootx() + app.transcript.winfo_width() + 80,
            )
        finally:
            app.close()
            root.update()


if __name__ == "__main__":
    unittest.main()
