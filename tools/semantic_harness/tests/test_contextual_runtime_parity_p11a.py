"""P11A proof for truthful bond catalogs and actor-centric Simulation UX."""

from __future__ import annotations

import gc
import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest
from copy import deepcopy

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.runtime.activity import ActivityLog
from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase


class RuntimeParityP11ATests(SemanticLabGuiTestCase):
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
        app = self.make_gui_app(root)

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
            app.main_tabs.select(app.simulation_tab)
            if not app.trace_panel_visible:
                app._toggle_trace_panel()
            root.update_idletasks()

            panels = [
                app.workbench_notebook.tab(tab, "text")
                for tab in app.workbench_notebook.tabs()
            ]
            self.assertEqual(
                panels,
                [
                    "NPC Target",
                    "Player",
                    "Relationship",
                    "World",
                    "Faction / Community",
                ],
            )
            self.assertEqual(
                [
                    app.trace_tabs.tab(tab, "text")
                    for tab in app.trace_tabs.tabs()
                    if app.trace_tabs.tab(tab, "text") in {
                        "Compare / Regression", "Debug", "World",
                    }
                ],
                ["Compare / Regression", "World", "Debug"],
            )
            self.assertEqual(str(app.persona_matrix_button.cget("text")), "Run comparison")
            self.assertEqual(str(app.world_knowledge_button.cget("text")), "Refresh world knowledge")
            self.assertEqual(str(app.snapshot_button.cget("text")), "Snapshot")
            self.assertEqual(str(app.restart_button.cget("text")), "Restart worker")

            compare_tab = next(
                tab for tab in app.trace_tabs.tabs()
                if app.trace_tabs.tab(tab, "text") == "Compare / Regression"
            )
            app.trace_tabs.select(compare_tab)
            app.compare_tabs.select(app.compare_context_frame)
            root.update_idletasks()
            wait_until(
                lambda: app.compare_utterance_box.winfo_ismapped()
                and app.matrix_dimension_box.winfo_ismapped()
                and app.persona_matrix_button.winfo_ismapped()
            )

            world_tab = next(
                tab for tab in app.workbench_notebook.tabs()
                if app.workbench_notebook.tab(tab, "text") == "World"
            )
            app.workbench_notebook.select(world_tab)
            root.update_idletasks()
            self.assertTrue(app.language_box.winfo_ismapped())

            diagnostics_tab = next(
                tab for tab in app.trace_tabs.tabs()
                if app.trace_tabs.tab(tab, "text") == "Debug"
            )
            app.trace_tabs.select(diagnostics_tab)
            app.debug_tabs.select(app.diagnostics_frame)
            root.update_idletasks()
            self.assertTrue(app.snapshot_button.winfo_ismapped())
            self.assertTrue(app.restart_button.winfo_ismapped())
        finally:
            app.close()
            del app
            del root
            gc.collect()

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_compact_normal_state_and_shared_agent_log(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "semantic-lab-ui.json"
            activity_path = Path(directory) / "semantic-lab.activity.jsonl"
            arguments = _parser().parse_args(
                [
                    "--ui-state",
                    str(state_path),
                    "--activity-log",
                    str(activity_path),
                ]
            )
            root = tk.Tk()
            app = SemanticHarnessApp(root, arguments)

            def wait_until(predicate: object, timeout: float = 15.0) -> None:
                deadline = time.monotonic() + timeout
                while not predicate() and time.monotonic() < deadline:
                    root.update()
                    time.sleep(0.02)
                self.assertTrue(predicate())

            try:
                wait_until(lambda: app.worker_ready)
                root.geometry("1080x700")
                root.update_idletasks()
                self.assertGreater(app.transcript.winfo_width(), 0)
                self.assertGreater(app.transcript.winfo_height(), 0)
                self.assertGreater(app.simulation_panes.winfo_width(), 0)

                root.geometry("1920x1080")
                root.update_idletasks()
                self.assertGreater(app.transcript.winfo_width(), 0)
                self.assertGreater(app.transcript.winfo_height(), 0)

                ActivityLog(path=activity_path, client="agent").record(
                    "agent",
                    "operation",
                    command="INPUT",
                    message="agent harness action",
                )
                app._poll_activity_log()
                self.assertIn("agent", app.activity_log_widget.get("1.0", "end"))

                talk_tab = next(
                    tab
                    for tab in app.compare_tabs.tabs()
                    if app.compare_tabs.tab(tab, "text") == "Talk parity"
                )
                app.main_tabs.select(app.log_tab)
                app.studio_notebook.select(app.studio_notebook.tabs()[-1])
                app.trace_tabs.select(app.compare_frame)
                app.compare_tabs.select(talk_tab)
                app.workbench_notebook.select(app.workbench_notebook.tabs()[1])
                # Exercise the real visible topology before switching context;
                # setting a hidden PanedWindow sash is not a user workflow and
                # can leave Tk with an invalid geometry during teardown.
                app.main_tabs.select(app.simulation_tab)
                root.update_idletasks()
                app.simulation_panes.sashpos(0, 700)
                root.update_idletasks()
                app.workflow_pane_split.sashpos(0, 280)
                root.update_idletasks()
                app.main_tabs.select(app.log_tab)
            finally:
                app.close()
                del app
                try:
                    root.destroy()
                except tk.TclError:
                    pass

            root2 = tk.Tk()
            app2 = SemanticHarnessApp(root2, arguments)

            def wait_until_reopened(predicate: object, timeout: float = 15.0) -> None:
                deadline = time.monotonic() + timeout
                while not predicate() and time.monotonic() < deadline:
                    root2.update()
                    time.sleep(0.02)
                self.assertTrue(predicate())

            try:
                wait_until_reopened(lambda: app2.worker_ready)
                root2.update()
                self.assertEqual(app2.main_tabs.index(app2.main_tabs.select()), 2)
                self.assertEqual(
                    app2.studio_notebook.index(app2.studio_notebook.select()),
                    len(app2.studio_notebook.tabs()) - 1,
                )
                restored_talk = app2.trace_tabs.tab(
                    app2.trace_tabs.select(), "text"
                )
                restored_inner_talk = app2.compare_tabs.tab(
                    app2.compare_tabs.select(), "text"
                )
                self.assertEqual(restored_talk, "Compare / Regression")
                self.assertEqual(restored_inner_talk, "Talk parity")
                app2.main_tabs.select(app2.simulation_tab)
                for _ in range(20):
                    root2.update()
                    time.sleep(0.05)
                self.assertEqual(app2.simulation_panes.sashpos(0), 700)
                # The responsive restore guard keeps the context dock usable
                # on the 1080px acceptance-test floor; a saved 280px sash is
                # restored at the effective 420px minimum.
                self.assertEqual(app2.workflow_pane_split.sashpos(0), 420)
            finally:
                app2.close()
                del app2
                try:
                    root2.destroy()
                except tk.TclError:
                    pass
                gc.collect()


if __name__ == "__main__":
    unittest.main()
