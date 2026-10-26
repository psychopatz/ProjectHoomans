"""S4 interaction checks for the existing Tk Semantic Lab surface."""

from __future__ import annotations

import gc
import os
import time
import tkinter as tk
import unittest
from copy import deepcopy

from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.ui.suggestion_projection import semantic_suggestion_rows
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase


class ContextualSuggestionsS4Tests(SemanticLabGuiTestCase):

    def test_topic_combobox_uses_the_worker_group_click_contract(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = self.make_gui_app(root)

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
                and bool(app.suggestion_projection.get("groups"))
            )
            diagnostic_rows = semantic_suggestion_rows(
                app.suggestion_projection,
                use_global_candidates=True,
            )
            self.assertEqual(app.suggestion_rows, [])
            self.assertFalse(app.suggestion_group_box.winfo_ismapped())
            self.assertTrue(diagnostic_rows)
            self.assertIn("diagnosticRows", app.suggestion_inspector.get("1.0", "end"))
            self.assertIn("diagnosticProjection", app.suggestion_inspector.get("1.0", "end"))
        finally:
            app.close()
            del app
            del root
            gc.collect()

    def test_existing_lab_renders_inspects_and_clicks_production_suggestions(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = self.make_gui_app(root)

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
            wait_until(lambda: not app.busy and app.last_response is not None)

            self.assertEqual(
                sum(button.winfo_ismapped() for button in app.suggestion_buttons),
                0,
            )
            self.assertEqual(app.suggestion_rows, [])
            self.assertIn("predicateTrace", app.suggestion_inspector.get("1.0", "end"))

            # Only the native production Conversation presentation is
            # clickable in the Response Channel.
            app.open_conversation_button.invoke()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            orders_index = next(
                index
                for index, row in enumerate(app.suggestion_rows)
                if row.get("id") == "companion.orders:open"
            )
            app.click_suggestion(orders_index)
            wait_until(
                lambda: not app.busy
                and any(row.get("id") == "action.follow" for row in app.suggestion_rows)
            )
            wait_until(lambda: not app.busy)
            transcript = app.transcript.get("1.0", "end")
            self.assertIn("Clicked semantic suggestion", transcript)
            self.assertIn("action.follow", app.suggestion_inspector.get("1.0", "end"))

            app.language_var.set("TL")
            app.set_language()
            wait_until(lambda: not app.busy)
            app.input_var.set("Are you okay?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            self.assertEqual(
                app.suggestion_primary_projection.get("schema"),
                "semantic.native_conversation_view.v1",
            )
            self.assertIn("diagnosticProjection", app.suggestion_inspector.get("1.0", "end"))
        finally:
            app.close()
            del app
            del root
            gc.collect()

    def test_identity_lie_choice_stays_in_inspect_until_native_session(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = self.make_gui_app(root)

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
                    for row in semantic_suggestion_rows(
                        app.suggestion_projection,
                        use_global_candidates=True,
                    )
                )
            )
            app.open_conversation_button.invoke()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
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
            self.assertEqual(app.suggestion_rows[lie_index]["id"], "identity.choice.lie_name")
            self.assertFalse(app.suggestion_interactive)
            self.assertIn("identity.choice.lie_name", app.suggestion_inspector.get("1.0", "end"))
        finally:
            app.close()
            del app
            del root
            gc.collect()

    def test_whats_up_gui_activates_hub_without_a_conversation_graph(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display unavailable")

        root = tk.Tk()
        app = self.make_gui_app(root)

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
            diagnostic_rows = semantic_suggestion_rows(
                app.suggestion_projection,
                use_global_candidates=True,
            )
            initial_ids = [row.get("id") for row in diagnostic_rows]
            self.assertTrue(
                {
                    "question.wellbeing",
                    "question.activity",
                    "question.weather",
                }
                <= set(initial_ids)
            )
            self.assertEqual(app.suggestion_rows, [])
            self.assertFalse(app.suggestion_group_box.winfo_ismapped())

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
            wait_until(
                lambda: not app.busy
                and (app.last_response.get("observation") or {})
                .get("suggestions", {})
                .get("activeHub", {})
                .get("id")
                == "whats_up"
            )

            observation = app.last_response.get("observation") or {}
            injured_suggestions = observation.get("suggestions") or {}
            injured_ids = [
                row.get("id")
                for row in semantic_suggestion_rows(
                    app.suggestion_projection,
                    use_global_candidates=True,
                )
            ]
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
            wait_until(lambda: not app.busy and app.last_response is not None)
            self.assertEqual(
                [
                    row.get("id")
                    for row in semantic_suggestion_rows(
                        app.suggestion_projection,
                        use_global_candidates=True,
                    )
                ],
                injured_ids,
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
        app = self.make_gui_app(root)
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
            wait_until(lambda: not app.busy and app.last_response is not None)
            self.assertNotIn(
                "Owned companion actions",
                [str(value) for value in app.suggestion_group_box["values"]],
            )
            self.assertFalse(
                any(
                    row.get("action") == "FOLLOW"
                    for row in semantic_suggestion_rows(
                        app.suggestion_projection,
                        use_global_candidates=True,
                    )
                )
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
        app = self.make_gui_app(root)

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
            self.assertEqual(app.suggestion_rows, [])
            self.assertIn("diagnosticRows", app.suggestion_inspector.get("1.0", "end"))
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
        app = self.make_gui_app(root)

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
