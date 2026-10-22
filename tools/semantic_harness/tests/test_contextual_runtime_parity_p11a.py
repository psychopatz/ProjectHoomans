"""P11A proof for truthful bond catalogs and actor-centric Simulation UX."""

from __future__ import annotations

import gc
import os
import time
import tkinter as tk
import unittest
from copy import deepcopy

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class RuntimeParityP11ATests(unittest.TestCase):
    def test_normal_relationship_catalog_matches_current_producers(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            persona = worker.persona_catalog()
            controls = worker.simulation_control_catalog()

        kinds = {row["kind"] for row in persona.get("relationshipKinds", [])}
        self.assertEqual(
            kinds,
            {"friend", "lover", "mother", "father", "sister", "brother"},
        )
        self.assertFalse(kinds & {"partner", "spouse", "cousin", "grandmother"})

        by_id = {row["id"]: row for row in controls.get("controls", [])}
        self.assertEqual(
            {
                by_id["persona.bondKind"]["options"][index]
                for index in range(len(by_id["persona.bondKind"]["options"]))
                if by_id["persona.bondKind"]["options"][index] != "none"
            },
            kinds,
        )

    def test_catalog_declares_the_four_actor_centric_workbench_panels(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            controls = worker.simulation_control_catalog()["controls"]

        workbench = [row for row in controls if row.get("workbench") is True]
        self.assertEqual(
            {row.get("workbenchPanel") for row in workbench},
            {"NPC Target", "Player", "Relationship", "World"},
        )
        self.assertTrue(
            any(
                row.get("workbenchPanel") == "NPC Target"
                and row.get("workbenchTab") == "Overview"
                for row in workbench
            )
        )
        self.assertTrue(
            any(
                row.get("workbenchPanel") == "Player"
                and row.get("workbenchTab") == "Overview"
                for row in workbench
            )
        )

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_simulation_exposes_actor_panels_and_named_diagnostics(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        def wait_until(predicate: object, timeout: float = 12.0) -> None:
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

            panels = [
                app.workbench_notebook.tab(tab, "text")
                for tab in app.workbench_notebook.tabs()
            ]
            self.assertEqual(
                panels,
                ["NPC Target", "Player", "Relationship", "World"],
            )
            self.assertEqual(
                [
                    app.trace_tabs.tab(tab, "text")
                    for tab in app.trace_tabs.tabs()
                    if app.trace_tabs.tab(tab, "text") in {
                        "Compare", "Diagnostics / Worker", "World Knowledge",
                    }
                ],
                ["Compare", "Diagnostics / Worker", "World Knowledge"],
            )
            self.assertEqual(str(app.persona_matrix_button.cget("text")), "Run comparison")
            self.assertEqual(str(app.world_knowledge_button.cget("text")), "Refresh world knowledge")
            self.assertEqual(str(app.snapshot_button.cget("text")), "Snapshot")
            self.assertEqual(str(app.restart_button.cget("text")), "Restart worker")

            compare_tab = next(
                tab for tab in app.trace_tabs.tabs()
                if app.trace_tabs.tab(tab, "text") == "Compare"
            )
            app.trace_tabs.select(compare_tab)
            root.update_idletasks()
            self.assertTrue(app.compare_utterance_box.winfo_ismapped())
            self.assertTrue(app.matrix_dimension_box.winfo_ismapped())
            self.assertTrue(app.persona_matrix_button.winfo_ismapped())

            world_tab = next(
                tab for tab in app.workbench_notebook.tabs()
                if app.workbench_notebook.tab(tab, "text") == "World"
            )
            app.workbench_notebook.select(world_tab)
            root.update_idletasks()
            self.assertTrue(app.language_box.winfo_ismapped())

            diagnostics_tab = next(
                tab for tab in app.trace_tabs.tabs()
                if app.trace_tabs.tab(tab, "text") == "Diagnostics / Worker"
            )
            app.trace_tabs.select(diagnostics_tab)
            root.update_idletasks()
            self.assertTrue(app.snapshot_button.winfo_ismapped())
            self.assertTrue(app.restart_button.winfo_ismapped())
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
