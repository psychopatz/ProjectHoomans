"""P11E live relationship preview and Compare surface tests."""

from __future__ import annotations

from copy import deepcopy
import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualRuntimeParityP11ETests(unittest.TestCase):
    def test_preview_uses_production_resolver_without_persisting(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["relationship"].update(
            {"approval": 20, "respect": 20, "familiarity": 20}
        )
        with LuaSemanticWorker(scenario) as worker:
            before = deepcopy(worker.snapshot()["scenario"]["npc"]["relationship"])
            preview = worker.relationship_preview(
                {"approval": -100, "respect": -20, "familiarity": 0}
            )
            after = worker.snapshot()["scenario"]["npc"]["relationship"]

        self.assertEqual(preview["schema"], "semantic.relationship.preview.v1")
        self.assertEqual(preview["standing"], "unknown")
        self.assertIn("familiarity", preview["reason"])
        self.assertFalse(preview["persisted"])
        self.assertEqual(before, after)

    def test_preview_reports_friend_progress_and_proposal_state(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["startingRelationship"] = {"kind": "friend"}
        scenario["npc"]["relationship"].update(
            {"approval": 72, "respect": 55, "familiarity": 63}
        )
        with LuaSemanticWorker(scenario) as worker:
            projection = worker.snapshot()["simulationProjection"]["relationship"]
            preview = worker.relationship_preview(
                {"approval": 72, "respect": 55, "familiarity": 63}
            )

        self.assertEqual(projection["friendBondThresholds"]["approval"], 80)
        self.assertEqual(projection["friendBondThresholds"]["respect"], 50)
        self.assertEqual(projection["friendBondThresholds"]["familiarity"], 60)
        self.assertEqual(preview["standing"], "friend")
        self.assertEqual(preview["proposal"]["reason"], "approval_threshold")

    def test_compare_exposes_runtime_parity_fields(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            result = worker.context_matrix([scenario], text="hello", maximum=1)

        row = result["rows"][0]
        self.assertEqual(result["schema"], "semantic.persona.matrix.v1")
        for key in (
            "npcResponse",
            "semanticHubChoices",
            "speechStyleContext",
            "relationship",
            "runtimeGraphPath",
        ):
            self.assertIn(key, row)
        self.assertIn("kind", row["runtimeGraphPath"])

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_live_preview_and_compare_are_reachable_from_simulation(self) -> None:
        state_dir = tempfile.TemporaryDirectory(prefix="projecthoomans-p11e-ui-")
        state_path = Path(state_dir.name) / "ui-state.json"
        root = tk.Tk()
        app = SemanticHarnessApp(
            root,
            _parser().parse_args(
                ["--ui-state", str(state_path), "--reset-ui-state"]
            ),
        )
        app._messagebox.showerror = lambda *_args, **_kwargs: None
        deadline = time.monotonic() + 15
        try:
            while not app.worker_ready and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(app.worker_ready)
            deadline = time.monotonic() + 15
            while app.busy and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertFalse(app.busy)

            app.workbench_control_fields["relationship.approval"].variable.set(-100)
            app.workbench_control_fields["relationship.respect"].variable.set(-20)
            app.workbench_control_fields["relationship.familiarity"].variable.set(0)
            preview_deadline = time.monotonic() + 5
            while (
                (
                    "UNKNOWN" not in app.relationship_preview_var.get()
                    or "familiarity" not in app.relationship_preview_var.get()
                )
                and time.monotonic() < preview_deadline
            ):
                root.update()
                time.sleep(0.02)
            self.assertIn("UNKNOWN", app.relationship_preview_var.get())
            self.assertIn("familiarity", app.relationship_preview_var.get())

            app.matrix_dimension_var.set("approval")
            app.compare_utterance_var.set("hello")
            app.inspect_persona_matrix()
            compare_deadline = time.monotonic() + 15
            while app.busy and time.monotonic() < compare_deadline:
                root.update()
                time.sleep(0.02)
            output = app.compare_output.get("1.0", "end")
            self.assertIn("semantic.persona.matrix.v1", output)
            self.assertIn("Speech style", output)
            self.assertIn("Standing", output)
        finally:
            app.close()
            state_dir.cleanup()


if __name__ == "__main__":
    unittest.main()
