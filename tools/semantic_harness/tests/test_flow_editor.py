"""Semantic Lab flow editor contracts against the production Lua registry."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.flow_editor import flow_graph_model
from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class FlowEditorTests(unittest.TestCase):
    def test_graph_model_exposes_nodes_and_transition_edges(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        greeting = next(flow for flow in catalog["flows"] if flow["id"] == "greeting")
        graph = flow_graph_model(greeting)
        self.assertEqual(graph["flowID"], "greeting")
        self.assertEqual(graph["initial"], "await_thanks")
        self.assertEqual(
            {node["id"] for node in graph["nodes"]},
            {"await_thanks", "complete"},
        )
        self.assertEqual(
            {
                (edge["fromNodeID"], edge["field"], edge["toNodeID"])
                for edge in graph["edges"]
            },
            {
                ("await_thanks", "onMatch", "complete"),
                ("await_thanks", "onRefuse", "cancel"),
                ("await_thanks", "onUnrelated", "suspend"),
            },
        )

    def test_editor_validates_registers_and_runs_a_new_flow_in_lua(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            self.assertEqual(
                [flow["id"] for flow in catalog["flows"]],
                ["identity", "wellbeing", "weather_context", "greeting"],
            )
            greeting = next(flow for flow in catalog["flows"] if flow["id"] == "greeting")

            invalid = deepcopy(greeting)
            invalid["id"] = "invalid_editor_flow"
            invalid["nodes"]["orphan"] = {"terminal": True}
            rejected = worker.validate_flow(invalid)
            self.assertFalse(rejected["valid"])
            self.assertEqual(rejected["reason"], "unreachable_node:orphan")

            draft = deepcopy(greeting)
            draft["id"] = "lab_editor_compliment"
            draft["owner"] = "SemanticLab"
            draft["triggers"] = [
                {"intent": "COMPLIMENT", "speechAct": "COMPLIMENT"},
            ]
            draft["nodes"]["await_thanks"]["responsePool"] = "semantic.compliment"
            draft["nodes"]["complete"]["responsePool"] = "semantic.thanks"
            valid = worker.validate_flow(draft)
            self.assertTrue(valid["valid"], valid)

            registered = worker.register_flow(draft)
            self.assertTrue(registered["registered"], registered)
            self.assertIn(
                "lab_editor_compliment",
                [flow["id"] for flow in registered["flows"]],
            )

            opening = worker.input("You look cute!")
            self.assertEqual(
                opening["observation"]["flow"]["flowId"],
                "lab_editor_compliment",
            )
            self.assertEqual(
                opening["observation"]["response"]["sourcePoolID"],
                "semantic.compliment",
            )

            followup = worker.input("thanks")
            self.assertEqual(
                followup["observation"]["flow"]["status"], "retired"
            )
            self.assertEqual(followup["observation"]["flow"]["activeAfter"], [])
            self.assertEqual(
                followup["observation"]["response"]["sourcePoolID"],
                "semantic.thanks",
            )


if __name__ == "__main__":
    unittest.main()
