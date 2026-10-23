"""P11J native Talk target parity coverage."""

from __future__ import annotations

from copy import deepcopy
import os
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualTalkParityP11JTests(unittest.TestCase):
    def test_catalog_is_production_owned_and_truthful(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.talk_catalog()

        self.assertEqual(catalog["schema"], "semantic.talk.catalog.v1")
        self.assertEqual(
            [row["id"] for row in catalog["targets"]],
            ["current", "colonist", "follower", "neutral", "hostile"],
        )
        self.assertEqual(
            next(row for row in catalog["targets"] if row["id"] == "hostile")["label"],
            "Hostile / Enemy",
        )

    def test_matrix_uses_native_target_facts_and_restores_base_scenario(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            matrix = worker.talk_matrix(text="hello")
            restored = worker.snapshot()["scenario"]

        rows = {row["target"]["id"]: row for row in matrix["rows"]}
        self.assertEqual(
            {row["target"]["targetType"] for row in rows.values()},
            {"colonist", "follower", "neutral", "hostile"},
        )
        self.assertEqual(rows["colonist"]["target"]["route"], "full_conversation")
        self.assertEqual(rows["follower"]["target"]["targetType"], "follower")
        self.assertEqual(rows["neutral"]["target"]["audience"], "neutral")
        self.assertEqual(rows["hostile"]["target"]["audience"], "hostile")
        self.assertEqual(rows["hostile"]["target"]["route"], "hostile_full_conversation")
        self.assertEqual(rows["hostile"]["runtimeGraphPath"]["kind"], "semantic_flow")
        self.assertIn(
            "action.follow",
            {choice["id"] for choice in rows["colonist"]["start"]["opening"]["choices"]},
        )
        self.assertIn(
            "conversation.root:menu:ceasefire",
            {choice["id"] for choice in rows["hostile"]["start"]["opening"]["choices"]},
        )
        self.assertNotIn("semanticLabTalkTarget", restored["runtime"])

    def test_cli_exposes_the_same_talk_operations(self) -> None:
        arguments = _parser().parse_args(["--no-gui", "--talk-matrix"])
        self.assertTrue(arguments.talk_matrix)
        self.assertIsNone(arguments.talk_start)
        self.assertEqual(arguments.talk_utterance, "hello")

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_talk_parity_surface_runs_the_real_worker(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))
        app._messagebox.showerror = lambda *_args, **_kwargs: None
        root.geometry("1080x700")
        deadline = time.monotonic() + 15
        try:
            while not app.worker_ready and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(app.worker_ready)
            labels = [
                app.trace_tabs.tab(tab, "text") for tab in app.trace_tabs.tabs()
            ]
            self.assertIn("Talk parity", labels)
            app.run_talk_matrix()
            deadline = time.monotonic() + 15
            while app.busy and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            output = app.talk_output.get("1.0", "end")
            self.assertIn("semantic.talk.parity.matrix.v1", output)
            self.assertIn("Hostile / Enemy", output)
            self.assertEqual(
                app.trace_tabs.tab(app.trace_tabs.select(), "text"),
                "Talk parity",
            )
        finally:
            app.close()


if __name__ == "__main__":
    unittest.main()
