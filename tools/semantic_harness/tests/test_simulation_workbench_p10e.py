"""P10E proof that the inline workbench applies and replays through Lua."""

from __future__ import annotations

import gc
import os
import tempfile
import time
import tkinter as tk
import unittest
from copy import deepcopy
from tkinter import ttk

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class SimulationWorkbenchP10ETests(unittest.TestCase):
    def test_semantic_dialogue_toggle_uses_worker_gate_and_saved_runtime(self) -> None:
        disabled = deepcopy(DEFAULT_SCENARIO)
        disabled["runtime"]["semanticDialogueEnabled"] = False
        with LuaSemanticWorker(disabled) as worker:
            snapshot = worker.snapshot()
            self.assertFalse(
                snapshot["scenario"]["runtime"]["semanticDialogueEnabled"]
            )
            self.assertEqual(snapshot["suggestions"]["candidates"], [])
            self.assertEqual(
                snapshot["suggestions"]["trace"][0]["reason"],
                "semantic_dialogue_disabled",
            )

            enabled = deepcopy(disabled)
            enabled["runtime"]["semanticDialogueEnabled"] = True
            worker.configure(enabled)
            refreshed = worker.snapshot()

        self.assertTrue(
            refreshed["scenario"]["runtime"]["semanticDialogueEnabled"]
        )
        self.assertTrue(refreshed["suggestions"]["candidates"])

    def test_worker_marks_quick_controls_in_the_shared_catalog(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.simulation_control_catalog()
        rows = {row["id"]: row for row in catalog.get("controls", [])}
        for control_id in (
            "runtime.language",
            "runtime.DTHoomans",
            "npc.role",
            "npc.health.state",
            "npc.activeBehavior",
            "relationship.bond",
            "persona.socialStyle",
            "relationship.approval",
            "relationship.respect",
            "relationship.familiarity",
            "relationship.state",
            "player.needs.hunger",
            "player.needs.thirst",
            "npc.needs.hunger",
            "npc.needs.thirst",
            "persona.personality.compassion",
        ):
            self.assertTrue(rows[control_id].get("workbench"), control_id)
            self.assertTrue(rows[control_id].get("workbenchSection"), control_id)
        self.assertEqual(rows["relationship.state"]["control"], "read_only")
        for control_id in (
            "world.timeOfDay",
            "world.worldAgeHours",
            "world.zombieKills",
            "world.weather",
            "world.weatherTransition",
        ):
            self.assertTrue(rows[control_id].get("workbench"), control_id)
            self.assertEqual(rows[control_id].get("workbenchPanel"), "World")
        for control_id in (
            "world.hunger",
            "world.thirst",
            "world.fatigue",
            "world.stress",
            "world.boredom",
            "world.panic",
        ):
            self.assertIs(rows[control_id].get("settingsVisible"), False, control_id)

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_workbench_applies_and_replays_latest_hub_utterance(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))
        errors: list[str] = []
        app._messagebox.showerror = lambda _title, message, **_kwargs: errors.append(str(message))

        def wait_until(predicate: object, timeout: float = 12.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            app.main_tabs.select(app.simulation_tab)
            self.assertEqual(
                int(app.load_saved_npc_button.grid_info()["column"]) + 1,
                int(app.reset_layout_button.grid_info()["column"]),
            )
            app._set_controls(False)
            self.assertEqual(str(app.reset_layout_button["state"]), "normal")
            self.assertEqual(str(app.advanced_toggle_button["state"]), "normal")
            app.reset_layout_button.invoke()
            self.assertIn("UI layout reset", app.transcript.get("1.0", "end"))
            app._set_controls(True)
            app.open_conversation_button.invoke()
            wait_until(
                lambda: (
                    not app.busy
                    and app.suggestion_primary_projection.get("schema")
                    == "semantic.native_conversation_view.v1"
                )
            )
            transcript = app.transcript.get("1.0", "end")
            self.assertRegex(transcript, r"NPC:\s+\S")
            self.assertEqual(
                app.suggestion_frame.cget("text"), "Response Channel"
            )
            self.assertEqual(
                app.preview_button.cget("text"), "Preview (no send)"
            )
            fields = app.workbench_control_fields
            self.assertIsInstance(fields["npc.health.state"].widget, ttk.Combobox)
            self.assertEqual(fields["relationship.bond"].kind, "read_only")
            self.assertIsInstance(fields["relationship.approval"].widget, tk.Scale)
            self.assertIsInstance(fields["persona.personality.compassion"].widget, tk.Scale)
            self.assertIsInstance(app.language_box, ttk.Combobox)
            self.assertEqual(fields["relationship.state"].kind, "read_only")

            app.open_runtime_settings()
            root.update()
            self.assertIsNotNone(app.settings_window)
            self.assertIn("npc.inventory", app.settings_control_fields)
            self.assertNotIn("npc.needs.hunger", app.settings_control_fields)
            self.assertNotIn("world.timeOfDay", app.settings_control_fields)
            app.settings_window.destroy()
            app.settings_window = None
            app.settings_control_fields = {}

            app.input_var.set("What's up?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            initial_ids = [row.get("id") for row in app.suggestion_rows]
            self.assertTrue(initial_ids)
            self.assertEqual(app.last_test_utterance, "What's up?")

            fields["npc.health.current"].set_value(95)
            fields["npc.health.body.overallPercent"].set_value(95)
            fields["relationship.approval"].variable.set(80)
            app.apply_and_replay()
            wait_until(
                lambda: not app.busy
                and app.last_response.get("input") == "What's up?"
            )

            replayed_ids = [row.get("id") for row in app.suggestion_rows]
            self.assertNotEqual(initial_ids, replayed_ids)
            self.assertTrue(replayed_ids)
            self.assertEqual(
                app.suggestion_primary_projection.get("schema"),
                "semantic.native_conversation_view.v1",
            )
            self.assertTrue(
                all(isinstance(row.get("semanticFrame"), dict) for row in app.suggestion_rows)
            )
            self.assertEqual(app.scenario["npc"]["health"]["state"], "normal")
            self.assertEqual(app.scenario["npc"]["health"]["current"], 95)
            self.assertEqual(app.scenario["npc"]["relationship"]["approval"], 80)
            self.assertEqual(errors, [])
            self.assertIn("Applied simulation context and replayed", app.transcript.get("1.0", "end"))

            fields["npc.health.current"].set_value(100)
            fields["npc.health.body.overallPercent"].set_value(100)
            app.apply_simulation_settings()
            wait_until(lambda: not app.busy and app.scenario["npc"]["health"]["current"] == 100)
            self.assertEqual(errors, [])
            self.assertIn("Applied simulation workbench settings", app.transcript.get("1.0", "end"))

            fields["relationship.respect"].variable.set(51)
            wait_until(
                lambda: (
                    not app.busy
                    and app.scenario["npc"]["relationship"]["respect"] == 51
                    and not app._pending_control_labels()
                )
            )
            self.assertIn("Auto-applied", app.workbench_status_var.get())
        finally:
            app.close()
            del app
            del root
            gc.collect()

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_replay_reexecutes_recorded_semantic_steps_from_clean_view(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        def wait_until(predicate: object, timeout: float = 12.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready and not app.busy)
            app.open_conversation_button.invoke()
            wait_until(
                lambda: (
                    not app.busy
                    and app.suggestion_primary_projection.get("schema")
                    == "semantic.native_conversation_view.v1"
                )
            )
            row = next(
                row
                for row in app.suggestion_rows
                if row.get("enabled") is True
            )
            app.click_suggestion(app.suggestion_rows.index(row))
            wait_until(lambda: not app.busy and len(app.replay_steps) == 1)

            app.input_var.set("What's up?")
            app.submit()
            wait_until(lambda: not app.busy and len(app.replay_steps) == 2)

            app.apply_and_replay()
            wait_until(
                lambda: not app.busy
                and "Replaying 2 recorded dialogue steps." in app.transcript.get("1.0", "end")
            )
            transcript = app.transcript.get("1.0", "end")
            self.assertGreaterEqual(transcript.count("PLAYER:"), 2)
            self.assertIn("Applied simulation context and replayed 2 steps.", transcript)
        finally:
            app.close()
            del app
            del root
            gc.collect()

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_conversation_first_workflow_keeps_layout_and_real_session(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = tk.Tk()
            app = SemanticHarnessApp(
                root,
                _parser().parse_args(
                    ["--ui-state", os.path.join(directory, "ui-state.json")]
                ),
            )
            try:
                def wait_until(predicate: object, timeout: float = 20.0) -> None:
                    deadline = time.monotonic() + timeout
                    while not predicate() and time.monotonic() < deadline:
                        root.update()
                        time.sleep(0.02)
                    self.assertTrue(predicate())

                wait_until(lambda: app.worker_ready and not app.busy)
                app.main_tabs.select(app.simulation_tab)
                root.geometry("1280x800")
                root.update_idletasks()
                app.simulation_panes.sashpos(0, 700)
                root.update_idletasks()
                app.workflow_pane_split.sashpos(0, 320)
                root.update_idletasks()
                saved_sash = app.workflow_pane_split.sashpos(0)
                app._save_ui_state()

                app.open_conversation_button.invoke()
                wait_until(
                    lambda: (
                        not app.busy
                        and (app.suggestion_primary_projection or {}).get("schema")
                        == "semantic.native_conversation_view.v1"
                    )
                )
                self.assertTrue(app.suggestion_rows)
                self.assertTrue(app.suggestion_interactive)

                choice_index = next(
                    index
                    for index, row in enumerate(app.suggestion_rows)
                    if row.get("enabled") is True
                )
                app.click_suggestion(choice_index)
                wait_until(lambda: not app.busy and app.last_response.get("type") == "semantic_click")

                app.input_var.set("What's up?")
                app.send_button.invoke()
                wait_until(lambda: not app.busy and app.last_test_utterance == "What's up?")

                app.workbench_control_fields["npc.health.current"].set_value(95)
                app.workbench_control_fields["npc.health.body.overallPercent"].set_value(95)
                app.workbench_apply_button.invoke()
                wait_until(
                    lambda: not app.busy
                    and app.scenario["npc"]["health"]["current"] == 95
                )
                app.open_conversation_button.invoke()
                wait_until(
                    lambda: (
                        not app.busy
                        and app.suggestion_rows
                        and app.suggestion_primary_projection.get("schema")
                        == "semantic.native_conversation_view.v1"
                    )
                )
                app.input_var.set("Let's continue.")
                app.send_button.invoke()
                wait_until(
                    lambda: not app.busy
                    and app.last_test_utterance == "Let's continue."
                )

                app.main_tabs.select(app.world_browser_tab)
                root.update_idletasks()
                app.main_tabs.select(app.simulation_tab)
                root.update_idletasks()
                self.assertEqual(app.workflow_pane_split.sashpos(0), saved_sash)
                self.assertTrue(app.suggestion_rows)
                self.assertEqual(
                    app.suggestion_primary_projection.get("schema"),
                    "semantic.native_conversation_view.v1",
                )
            finally:
                app.close()
                del app
                del root
                gc.collect()


if __name__ == "__main__":
    unittest.main()
