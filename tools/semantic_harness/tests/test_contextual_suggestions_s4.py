"""S4 interaction checks for the existing Tk Semantic Lab surface."""

from __future__ import annotations

import gc
import os
import tempfile
import time
import tkinter as tk
import unittest
from copy import deepcopy

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualSuggestionsS4Tests(unittest.TestCase):
    def setUp(self) -> None:
        self._gui_state_dir = tempfile.TemporaryDirectory(
            prefix="projecthoomans-s4-ui-"
        )
        self._gui_state_path = os.path.join(
            self._gui_state_dir.name, "ui-state.json"
        )

    def tearDown(self) -> None:
        self._gui_state_dir.cleanup()

    def _gui_arguments(self):
        """Keep GUI assertions isolated from the user's saved layout state."""

        return _parser().parse_args(
            [
                "--ui-state",
                self._gui_state_path,
                "--reset-ui-state",
            ]
        )

    def test_topic_combobox_uses_the_worker_group_click_contract(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())

        def wait_until(predicate: object, timeout: float = 10.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            app.input_var.set("what time is it")
            app.submit()
            wait_until(
                lambda: not app.busy
                and app.suggestion_group_box.get() == "Time and date"
            )
            owned_display = next(
                display
                for display, group_id in app.suggestion_group_ids_by_display.items()
                if group_id == "companion.orders"
            )
            app.suggestion_group_box.set(owned_display)
            app._on_suggestion_group()
            wait_until(
                lambda: not app.busy
                and any(row.get("action") == "FOLLOW" for row in app.suggestion_rows)
            )
            self.assertEqual(app.suggestion_group_box.get(), owned_display)
            self.assertIn(
                "semantic_suggestions",
                app.suggestion_response.get("choiceSurface", {}).get("source", ""),
            )
            self.assertEqual(app.suggestion_response.get("transport"), [])
        finally:
            app.close()
            del app
            del root
            gc.collect()

    def test_existing_lab_renders_inspects_and_clicks_production_suggestions(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())

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

            self.assertEqual(
                sum(button.winfo_ismapped() for button in app.suggestion_buttons),
                len(app.suggestion_rows),
            )
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
            self.assertTrue(
                all(
                    button.winfo_ismapped()
                    for button in app.suggestion_buttons[: len(app.suggestion_rows)]
                )
            )
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
            del app
            del root
            gc.collect()

    def test_identity_lie_choice_reaches_authoritative_worker(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())

        def wait_until(predicate: object, timeout: float = 10.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            app.main_tabs.select(app.simulation_tab)
            app.input_var.set("who are you")
            app.submit()
            wait_until(
                lambda: not app.busy
                and any(
                    row.get("id") == "identity.choice.lie_name"
                    for row in app.suggestion_rows
                )
            )

            lie_index = next(
                index
                for index, row in enumerate(app.suggestion_rows)
                if row.get("id") == "identity.choice.lie_name"
            )
            app.click_suggestion(lie_index)
            wait_until(lambda: not app.busy)

            transcript = app.transcript.get("1.0", "end")
            self.assertIn("PLAYER: I'll go by ", transcript)
            self.assertIn("NPC: I don't believe you.", transcript)
            self.assertNotIn("NPC: Understood.", transcript)
        finally:
            app.close()
            del app
            del root
            gc.collect()

    def test_whats_up_gui_activates_hub_without_a_conversation_graph(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())

        def wait_until(predicate: object, timeout: float = 10.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            app.main_tabs.select(app.simulation_tab)
            app.input_var.set("whats up")
            app.submit()
            wait_until(lambda: not app.busy and app.last_response is not None)

            observation = app.last_response.get("observation") or {}
            suggestions = observation.get("suggestions") or {}
            self.assertEqual(
                suggestions.get("activeHub"),
                {"id": "whats_up", "route": "semantic_hub"},
            )
            self.assertIsNone(observation.get("conversationBlock"))
            self.assertEqual(
                observation["conversationGraph"]["graphKind"],
                "semantic_hub",
            )
            self.assertNotIn(
                "semantic_hub.whats_up",
                [row.get("id") for row in app.suggestion_rows],
            )
            initial_ids = [row.get("id") for row in app.suggestion_rows]
            self.assertTrue(
                {
                    "question.wellbeing",
                    "question.activity",
                    "question.weather",
                }
                <= set(initial_ids)
            )
            self.assertIn("What's up", app.suggestion_group_box.get())

            # Reconfigure the live worker through Tk, then replay the utterance
            # through the regular input surface. Apply + Replay is P10E work.
            injured_family = deepcopy(app.scenario)
            injured_family["npc"]["healthState"] = "injured"
            injured_family["npc"]["startingRelationship"] = {
                "kind": "mother",
                "source": "starting_companion_trait",
            }
            injured_family["npc"]["relationship"].update(
                {"approval": 80, "respect": 70, "familiarity": 80}
            )
            configured = {"done": False}

            def configured_scenario(_: dict) -> None:
                app.scenario = injured_family
                configured["done"] = True

            app._start_operation(
                lambda worker: worker.configure(injured_family),
                configured_scenario,
            )
            wait_until(lambda: not app.busy and configured["done"])
            app.input_var.set("What's up?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))

            observation = app.last_response.get("observation") or {}
            injured_suggestions = observation.get("suggestions") or {}
            injured_ids = [row.get("id") for row in app.suggestion_rows]
            self.assertEqual(
                injured_suggestions.get("activeHub", {}).get("id"),
                "whats_up",
            )
            self.assertNotEqual(initial_ids, injured_ids)
            self.assertEqual(injured_ids[0], "question.health")
            self.assertIn("social.personal_check_in", injured_ids)
            self.assertEqual(
                observation["conversationGraph"]["graphKind"],
                "semantic_hub",
            )
            self.assertIsNone(observation.get("conversationBlock"))

            app.input_var.set("What's up?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            self.assertEqual(
                [row.get("id") for row in app.suggestion_rows], injured_ids
            )
        finally:
            app.close()
            del app
            del root
            gc.collect()

    def test_npc_profile_selection_is_staged_until_workbench_apply(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())
        errors: list[str] = []
        app._messagebox.showerror = lambda _title, message, **_kwargs: errors.append(str(message))

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
            self.assertEqual(app.scenario["runtime"].get("semanticLabProfile"), "companion")
            self.assertFalse(app.busy)
            app.apply_simulation_settings()
            wait_until(lambda: not app.busy)
            self.assertEqual(errors, [])
            self.assertIs(
                app.scenario["npc"]["actorAuthority"]["eligible"], False
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
            del app
            del root
            gc.collect()

    def test_simulation_layout_at_minimum_size_keeps_runtime_controls_visible(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())

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
            self.assertEqual(root.minsize(), (1080, 700))
            self.assertGreaterEqual(root.winfo_width(), 1080)
            self.assertGreaterEqual(root.winfo_height(), 700)

            for widget in (
                app.npc_profile_box,
                app.workbench_apply_button,
                app.replay_button,
                app.send_button,
                app.status_label,
            ):
                self.assertTrue(widget.winfo_ismapped())
            self.assertIn("Compare / Regression", [app.trace_tabs.tab(tab, "text") for tab in app.trace_tabs.tabs()])
            self.assertIn("Debug", [app.trace_tabs.tab(tab, "text") for tab in app.trace_tabs.tabs()])

            # Root semantic suggestions are intentionally visible before the
            # first typed turn, so this is a populated baseline rather than a
            # blank placeholder panel.
            initial_panel_height = app.suggestion_frame.winfo_height()
            app.input_var.set("whats up")
            app.submit()
            wait_until(
                lambda: not app.busy
                and bool(
                    (app.last_response.get("observation") or {})
                    .get("suggestions", {})
                    .get("activeHub")
                )
            )
            root.update_idletasks()

            self.assertEqual(
                app.trace_tabs.tab(app.trace_tabs.select(), "text"), "Graph"
            )
            self.assertEqual(
                app.graph_tabs.tab(app.graph_tabs.select(), "text"),
                "Dialogue graph",
            )
            self.assertTrue(app.hub_diagnostics.winfo_exists())
            observation = app.last_response.get("observation") or {}
            self.assertEqual(
                observation["suggestions"]["activeHub"]["id"], "whats_up"
            )
            self.assertEqual(
                observation["conversationGraph"]["graphKind"],
                "semantic_hub",
            )
            self.assertIsNone(observation.get("conversationBlock"))
            self.assertNotIn(
                "semantic_hub.whats_up",
                [row.get("id") for row in app.suggestion_rows],
            )
            self.assertGreaterEqual(
                app.suggestion_frame.winfo_height(), initial_panel_height
            )
            self.assertGreater(
                app.send_button.winfo_rooty(), app.suggestion_frame.winfo_rooty()
            )
            pane_right = (
                app.simulation_panes.winfo_rootx()
                + app.simulation_panes.winfo_width()
            )
            for button in (
                app.reset_button,
                app.load_button,
                app.settings_button,
                app.save_button,
            ):
                self.assertLessEqual(
                    button.winfo_rootx() + button.winfo_width(),
                    pane_right,
                )
            simulation_right = (
                app.simulation_panes.winfo_rootx()
                + app.simulation_panes.winfo_width()
            )
            self.assertLessEqual(
                app.npc_profile_box.winfo_rootx()
                + app.npc_profile_box.winfo_width(),
                simulation_right,
            )
        finally:
            app.close()
            del app
            del root
            gc.collect()

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_simulation_layout_at_normal_desktop_size(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, self._gui_arguments())

        def wait_until(predicate: object, timeout: float = 12.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            root.geometry("1280x800")
            app.main_tabs.select(app.simulation_tab)
            wait_until(lambda: app.worker_ready)
            root.update_idletasks()
            self.assertEqual((root.winfo_width(), root.winfo_height()), (1280, 800))
            for widget in (
                app.npc_profile_box,
                app.workbench_apply_button,
                app.replay_button,
                app.send_button,
                app.status_label,
            ):
                self.assertTrue(widget.winfo_ismapped())
            self.assertIn("Compare / Regression", [app.trace_tabs.tab(tab, "text") for tab in app.trace_tabs.tabs()])

            app.input_var.set("What's up?")
            app.submit()
            wait_until(
                lambda: not app.busy
                and (app.last_response.get("observation") or {})
                .get("suggestions", {})
                .get("activeHub", {}).get("id") == "whats_up"
            )
            root.update_idletasks()
            self.assertEqual(
                app.trace_tabs.tab(app.trace_tabs.select(), "text"), "Graph"
            )
            self.assertEqual(
                app.graph_tabs.tab(app.graph_tabs.select(), "text"),
                "Dialogue graph",
            )
            self.assertTrue(app.hub_diagnostics.winfo_exists())
            self.assertIn("question.wellbeing", app.hub_diagnostics.get("1.0", "end"))
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
