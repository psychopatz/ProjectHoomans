"""P11F shared runtime graph adapters and interaction tests."""

from __future__ import annotations

from copy import deepcopy
import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.flow_editor.model import conversation_graph_model
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualRuntimeGraphP11FTests(unittest.TestCase):
    def test_greeting_uses_runtime_flow_graph_with_current_transition(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            response = worker.input("hello")

        graph = response["observation"]["conversationGraph"]
        self.assertEqual(graph["graphKind"], "semantic_flow")
        self.assertEqual(graph["flowID"], "greeting")
        self.assertEqual(graph["currentNodeID"], "await_thanks")
        self.assertTrue(any(edge["field"] == "onMatch" for edge in graph["edges"]))
        model = conversation_graph_model(graph)
        self.assertEqual(model["graphKind"], "semantic_flow")
        self.assertIn("current", {node["state"] for node in model["nodes"]})

    def test_whats_up_uses_provider_candidate_graph_and_retains_visit_history(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            entered = worker.input("What's up?")
            graph = entered["observation"]["conversationGraph"]
            candidate = next(
                row
                for row in entered["observation"]["suggestions"]["candidates"]
                if row["id"] == "question.activity"
            )
            clicked = worker.suggestion_click(candidate["frame"])

        self.assertEqual(graph["graphKind"], "semantic_hub")
        self.assertTrue(
            any(edge.get("clickable") is True for edge in graph["edges"])
        )
        after = clicked["observation"]["conversationGraph"]
        self.assertEqual(after["graphKind"], "semantic_hub")
        self.assertIn("question.activity", after["visitedNodeIDs"])
        visited_node = next(
            node
            for node in after["nodes"]
            if node["id"] == "candidate:question.activity"
        )
        self.assertEqual(visited_node["state"], "completed")
        self.assertTrue(visited_node["visited"])

    def test_authored_conversation_block_keeps_existing_graph_adapter(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "trader")
        with LuaSemanticWorker(scenario) as worker:
            entered = worker.input("What's up?")
            candidate = next(
                row
                for row in entered["observation"]["suggestions"]["candidates"]
                if row["id"] == "dynamictrading.trade"
            )
            clicked = worker.suggestion_click(candidate["frame"])

        graph = clicked["observation"]["conversationGraph"]
        self.assertEqual(graph["graphKind"], "conversation_block")
        model = conversation_graph_model(graph)
        self.assertEqual(model["graphKind"], "conversation_block")
        self.assertIn("current", {node["state"] for node in model["nodes"]})

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_simulation_graph_pane_follows_hello_and_whats_up(self) -> None:
        state_dir = tempfile.TemporaryDirectory(prefix="projecthoomans-p11f-ui-")
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
            for utterance, expected_kind in (("hello", "semantic_flow"), ("What's up?", "semantic_hub")):
                app.input_var.set(utterance)
                app.submit()
                deadline = time.monotonic() + 15
                while app.busy and time.monotonic() < deadline:
                    root.update()
                    time.sleep(0.02)
                self.assertEqual(app.dialogue_graph_pane._draft["graphKind"], expected_kind)
                self.assertEqual(
                    app.trace_tabs.tab(app.trace_tabs.select(), "text"), "Graph"
                )
                self.assertEqual(
                    app.graph_tabs.tab(app.graph_tabs.select(), "text"),
                    "Dialogue graph",
                )
        finally:
            app.close()
            state_dir.cleanup()


if __name__ == "__main__":
    unittest.main()
