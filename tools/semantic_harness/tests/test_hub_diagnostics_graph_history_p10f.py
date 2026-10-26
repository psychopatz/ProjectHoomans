"""P10F proof for safe hub diagnostics and presentation-only graph history."""

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
from tools.semantic_harness.ui.shell import (
    SemanticHarnessApp,
    semantic_hub_diagnostic_projection,
)
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase


def _conversation_graph(graph_id: str) -> dict:
    """A non-hub ConversationBlock renderer fixture with a completed path."""

    return {
        "schema": "semantic_lab.graph.v1",
        "schemaVersion": 1,
        "graphKind": "conversation_block",
        "graphID": graph_id,
        "title": "projecthoomans:small_talk",
        "blockID": "small_talk:history-fixture",
        "categoryID": "projecthoomans:small_talk",
        "entryNodeID": "opening",
        "currentNodeID": "opening",
        "visitedNodeIDs": ["past"],
        "nodes": [
            {
                "id": "opening",
                "title": "opening",
                "npcText": "What would you like to talk about?",
                "state": "current",
                "current": True,
                "visited": False,
                "choices": [],
            },
            {
                "id": "past",
                "title": "past",
                "npcText": "We spoke about the road yesterday.",
                "state": "visited",
                "current": False,
                "visited": True,
                "choices": [],
            },
        ],
        "edges": [
            {
                "id": f"{graph_id}:return",
                "fromNodeID": "opening",
                "toNodeID": "past",
                "label": "Revisit the road",
                "choiceID": "revisit",
                "state": "available",
                "clickable": True,
                "frame": {
                    "kind": "semantic_click_frame",
                    "candidateID": "conversation.choice.small_talk.opening.revisit",
                },
            },
            {
                "id": f"{graph_id}:close",
                "fromNodeID": "past",
                "toNodeID": "$root",
                "label": "Return to conversation root",
                "choiceID": "close",
                "state": "root_exit",
                "clickable": False,
            },
        ],
    }


class HubDiagnosticsGraphHistoryP10FTests(SemanticLabGuiTestCase):
    def test_real_worker_hub_projection_has_safe_provider_owned_diagnostics(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            response = worker.input("What's up?")
        suggestions = response["observation"]["suggestions"]
        diagnostics = semantic_hub_diagnostic_projection(suggestions)

        self.assertEqual(diagnostics["activeHub"], {"id": "whats_up", "route": "semantic_hub"})
        self.assertTrue(diagnostics["privacySafe"])
        self.assertGreaterEqual(diagnostics["candidateCount"], 4)
        candidate = next(
            row for row in diagnostics["candidates"]
            if row["candidateID"] == "question.wellbeing"
        )
        self.assertEqual(candidate["providerID"], "projecthoomans.static_questions")
        self.assertEqual(candidate["semanticOwner"], "projecthoomans.semantic.wellbeing")
        self.assertEqual(candidate["rankClass"], "ACTIVE_TOPIC")
        self.assertEqual(candidate["eligibility"], "eligible")
        self.assertIsNone(candidate["hiddenReason"])
        self.assertEqual(candidate["contextReason"], "non-hostile public topic")
        self.assertTrue(candidate["translationKeys"]["label"])
        self.assertEqual(candidate["resolvedLabel"], "Ask about wellbeing")
        self.assertEqual(candidate["semanticDestination"]["hubID"], "whats_up")
        self.assertEqual(candidate["semanticFrame"]["kind"], "semantic_click_frame")
        self.assertNotIn("trace", diagnostics)

        unsafe = deepcopy(suggestions)
        unsafe["privacy"]["privateFieldsInspected"] = True
        closed = semantic_hub_diagnostic_projection(unsafe)
        self.assertTrue(closed["diagnosticsHidden"])
        self.assertEqual(closed["candidates"], [])

        private = deepcopy(suggestions)
        private["candidates"].append(
            {"id": "private.secret", "visibility": "private", "display": {"label": "secret"}}
        )
        filtered = semantic_hub_diagnostic_projection(private)
        self.assertNotIn(
            "private.secret",
            {row["candidateID"] for row in filtered["candidates"]},
        )

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_unifies_hub_graph_and_retains_authored_history(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
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
            app.input_var.set("What's up?")
            app.submit()
            wait_until(
                lambda: not app.busy
                and app.last_response.get("observation", {})
                .get("suggestions", {})
                .get("activeHub", {}).get("id") == "whats_up"
            )
            self.assertEqual(
                app.trace_tabs.tab(app.trace_tabs.select(), "text"), "Graph"
            )
            self.assertEqual(
                app.graph_tabs.tab(app.graph_tabs.select(), "text"),
                "Dialogue graph",
            )
            self.assertIn("question.wellbeing", app.hub_diagnostics.get("1.0", "end"))
            self.assertIn("ACTIVE_TOPIC", app.hub_diagnostics.get("1.0", "end"))
            self.assertEqual(
                app.dialogue_graph_pane._draft["graphKind"], "semantic_hub"
            )

            first = _conversation_graph("conversation_block:history-first")
            second = _conversation_graph("conversation_block:history-second")
            app.dialogue_graph_pane.set_graph(first)
            visited = next(
                row for row in app.dialogue_graph_pane.graph_model()["nodes"]
                if row["id"] == "past"
            )
            self.assertTrue(visited["visited"])
            app._show_response(app.last_response)
            self.assertEqual(
                app.dialogue_graph_pane._draft["graphKind"], "semantic_hub"
            )
            self.assertEqual(
                app.trace_tabs.tab(app.trace_tabs.select(), "text"), "Graph"
            )
            self.assertEqual(
                app.graph_tabs.tab(app.graph_tabs.select(), "text"),
                "Dialogue graph",
            )

            app.dialogue_graph_pane.set_graph(second)
            self.assertEqual(
                app.dialogue_graph_pane._draft["graphID"], second["graphID"]
            )
            app.dialogue_graph_pane.clear_button.invoke()
            self.assertIsNone(app.dialogue_graph_pane._draft)

            app.dialogue_graph_pane.set_graph(first)
            app.reset()
            wait_until(lambda: not app.busy)
            self.assertIsNone(app.dialogue_graph_pane._draft)
            self.assertEqual(errors, [])
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
