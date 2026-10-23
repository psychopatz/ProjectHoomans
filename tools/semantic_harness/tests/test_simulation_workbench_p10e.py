"""P10E proof that the inline workbench applies and replays through Lua."""

from __future__ import annotations

import gc
import os
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
    def test_worker_marks_quick_controls_in_the_shared_catalog(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.simulation_control_catalog()
        rows = {row["id"]: row for row in catalog.get("controls", [])}
        for control_id in (
            "runtime.language",
            "runtime.DTHoomans",
            "npc.role",
            "npc.healthState",
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
            fields = app.workbench_control_fields
            self.assertIsInstance(fields["npc.healthState"].widget, ttk.Combobox)
            self.assertEqual(fields["relationship.bond"].kind, "read_only")
            self.assertIsInstance(fields["relationship.approval"].widget, tk.Scale)
            self.assertIsInstance(fields["persona.personality.compassion"].widget, tk.Scale)
            self.assertIsInstance(app.language_box, ttk.Combobox)
            self.assertEqual(fields["relationship.state"].kind, "read_only")

            app.input_var.set("What's up?")
            app.submit()
            wait_until(lambda: not app.busy and bool(app.suggestion_rows))
            initial_ids = [row.get("id") for row in app.suggestion_rows]
            self.assertTrue(initial_ids)
            self.assertEqual(app.last_test_utterance, "What's up?")

            fields["npc.healthState"].set_value("injured")
            fields["relationship.approval"].variable.set(80)
            app.apply_and_replay()
            wait_until(
                lambda: not app.busy
                and app.last_response.get("input") == "What's up?"
            )

            replayed_ids = [row.get("id") for row in app.suggestion_rows]
            self.assertNotEqual(initial_ids, replayed_ids)
            self.assertIn("question.health", replayed_ids)
            self.assertEqual(
                replayed_ids[0],
                "semantic.back_to_root:semantic_hub.whats_up",
            )
            self.assertEqual(app.scenario["npc"]["healthState"], "injured")
            self.assertEqual(app.scenario["npc"]["relationship"]["approval"], 80)
            self.assertEqual(errors, [])
            self.assertIn("Applied simulation context and replayed", app.transcript.get("1.0", "end"))

            fields["npc.healthState"].set_value("healthy")
            app.apply_simulation_settings()
            wait_until(lambda: not app.busy and app.scenario["npc"]["healthState"] == "healthy")
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


if __name__ == "__main__":
    unittest.main()
