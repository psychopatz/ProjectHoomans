"""P8D contracts for the existing production-backed Semantic Lab workflow."""

from __future__ import annotations

from copy import deepcopy
import os
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualSemanticLabPersonaP8DTests(unittest.TestCase):
    def test_baseline_replay_and_matrix_use_real_worker_traces(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        warm = deepcopy(scenario)
        warm["runtime"]["semanticLabMatrixLabel"] = "warm"
        warm["npc"]["traits"] = ["pnc_friendly"]
        warm["npc"]["personality"] = {
            "socialStyle": "friendly",
            "compassion": 0.95,
            "sociability": 0.95,
            "forgiveness": 0.9,
            "bravery": 0.8,
            "aggression": 0.1,
        }
        warm["npc"]["relationship"] = {
            "approval": 80,
            "respect": 70,
            "familiarity": 100,
        }

        with LuaSemanticWorker(scenario) as worker:
            baseline = worker.capture_baseline("how are you doing?")
            replay = worker.apply_and_replay("how are you doing?")
            matrix = worker.context_matrix(
                [scenario, warm], text="how are you doing?", maximum=2
            )

        self.assertEqual(baseline["schema"], "semantic.persona.baseline.v1")
        self.assertEqual(baseline["utterance"], "how are you doing?")
        self.assertEqual(replay["schema"], "semantic.persona.apply_replay.v1")
        self.assertEqual(replay["utterance"], "how are you doing?")
        self.assertEqual(matrix["schema"], "semantic.persona.matrix.v1")
        self.assertEqual(len(matrix["rows"]), 2)
        for row in matrix["rows"]:
            self.assertIn("response", row)
            self.assertIn("realizationFamily", row["response"])
            self.assertIn("realizationVariant", row["response"])
            self.assertIn("candidateOrder", row["suggestions"])
            self.assertEqual(
                row["suggestions"]["candidateOrder"],
                [candidate["id"] for candidate in row["suggestions"]["candidates"]],
            )
        self.assertNotEqual(
            matrix["rows"][0]["response"]["realizationVariant"],
            matrix["rows"][1]["response"]["realizationVariant"],
        )

    def test_inspector_exposes_coverage_and_response_trace(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            record = worker.input("how are you doing?")
            catalog = worker.persona_catalog()

        record["personaCatalog"] = catalog
        persona = build_conversation_inspector(record)["personaChoices"]
        self.assertIn("responseTrace", persona)
        self.assertIn("speechRealizationCoverage", persona)
        self.assertEqual(
            persona["speechRealizationCoverage"]["schema"],
            "pnc.speech.realization.catalog.v1",
        )
        self.assertEqual(
            persona["responseTrace"]["semanticFrame"].get("intent"),
            "QUESTION",
        )

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_existing_lab_renders_p8d_controls_and_runs_matrix(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        def wait_until(predicate: object, timeout: float = 15.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            self.assertEqual(
                tuple(app.matrix_dimension_box["values"]),
                ("persona", "approval", "respect", "familiarity", "bond", "language"),
            )
            self.assertEqual(str(app.capture_baseline_button.cget("text")), "Capture baseline")
            self.assertEqual(str(app.replay_button.cget("text")), "Apply + replay")

            app.input_var.set("how are you doing?")
            app.capture_baseline()
            wait_until(lambda: not app.busy and bool(app.baseline_record))
            self.assertEqual(
                app.baseline_record["schema"], "semantic.persona.baseline.v1"
            )

            app.apply_and_replay()
            wait_until(lambda: not app.busy and app.last_response.get("type") == "turn")
            self.assertEqual(app.last_response.get("input"), "how are you doing?")

            app.matrix_dimension_var.set("bond")
            app.inspect_persona_matrix()
            wait_until(lambda: not app.busy and "semantic.persona.matrix.v1" in app.compare_output.get("1.0", "end"))
            trace = app.compare_output.get("1.0", "end")
            self.assertIn("mother", trace)
            self.assertIn("lover", trace)
            self.assertIn("candidateOrder", trace)
        finally:
            app.close()
            del app


if __name__ == "__main__":
    unittest.main()
