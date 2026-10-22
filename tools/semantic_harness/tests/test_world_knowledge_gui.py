"""Headless-display smoke for the existing Semantic Lab WKG pane."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import tkinter as tk
import unittest

from tools.semantic_harness.tests.test_grounded_world_knowledge_gossip import (
    scenario_for,
)
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class WorldKnowledgeGuiTests(unittest.TestCase):
    def test_existing_semantic_lab_pane_renders_worker_inspection(self) -> None:
        scenario = scenario_for("alice", "EN", [
            {
                "actorID": "actor:alice",
                "factIndex": 1,
                "provenance": "witnessed",
            },
        ])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "world-knowledge.json"
            path.write_text(json.dumps(scenario), encoding="utf-8")
            arguments = argparse.Namespace(
                repository=str(Path(__file__).resolve().parents[3]),
                core_repository=str(Path(__file__).resolve().parents[4] / "psychopatzCore"),
                lua="lua",
                startup_timeout=8.0,
                timeout=5.0,
                shutdown_timeout=1.0,
                scenario=str(path),
                language=None,
            )
            root = tk.Tk()
            app = SemanticHarnessApp(root, arguments)
            captured: list[str] = []
            errors: list[BaseException] = []
            requested = False

            def poll() -> None:
                nonlocal requested
                if app.closed:
                    return
                if app.worker_ready and not app.busy and not requested:
                    requested = True
                    app.inspect_world_knowledge()
                elif requested and not app.busy:
                    captured.append(app.world_knowledge_inspector.get("1.0", "end"))
                    app.close()
                    return
                root.after(50, poll)

            def timeout() -> None:
                if not app.closed:
                    errors.append(AssertionError("GUI inspection did not finish"))
                    app.close()

            root.after(50, poll)
            root.after(12000, timeout)
            root.mainloop()

        self.assertFalse(errors, errors)
        self.assertTrue(captured)
        self.assertIn('"factLedger"', captured[0])
        self.assertIn('"whyActorKnows"', captured[0])
        self.assertIn('"finalRealization"', captured[0])


if __name__ == "__main__":
    unittest.main()
