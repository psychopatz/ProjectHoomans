"""Semantic Lab flow editor contracts against the production Lua registry."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.flow_editor import flow_graph_model, graph_render_mode
from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class FlowEditorTests(unittest.TestCase):
    def test_graph_render_mode_reduces_detail_before_labels_overlap(self) -> None:
        self.assertEqual(graph_render_mode(0.39), "overview")
        self.assertEqual(graph_render_mode(0.65), "compact")
        self.assertEqual(graph_render_mode(1.0), "detail")

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

    def test_catalog_exposes_engine_facts_and_commands(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        fact_ids = {fact["id"] for fact in catalog["factCatalog"]}
        self.assertIn("world.time.week", fact_ids)
        self.assertIn("world.weather.transition", fact_ids)
        self.assertIn("player.stats.zombie_kills", fact_ids)
        self.assertIn("FOLLOW", catalog["commandCatalog"])
        self.assertIn("CONSUME", catalog["commandCatalog"])
        action_ids = {action["id"] for action in catalog["actionCatalog"]}
        self.assertIn("GIFT", action_ids)
        trigger_ids = {trigger["id"] for trigger in catalog["triggerCatalog"]}
        self.assertIn("pnc.social.gift_here", trigger_ids)
        gift_trigger = next(
            trigger for trigger in catalog["triggerCatalog"]
            if trigger["id"] == "pnc.social.gift_here"
        )
        self.assertEqual(gift_trigger["frame"]["action"], "GIFT")
        gift_action = next(
            action for action in catalog["actionCatalog"] if action["id"] == "GIFT"
        )
        self.assertEqual(gift_action["frame"]["intent"], "OFFER")
        wait_at_action = next(
            action for action in catalog["actionCatalog"] if action["id"] == "WAIT_AT"
        )
        self.assertNotIn("target", wait_at_action["frame"])

    def test_fact_gate_is_accepted_by_production_registry(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            weather = next(flow for flow in catalog["flows"] if flow["id"] == "weather_context")
            draft = deepcopy(weather)
            draft["id"] = "lab_engine_fact_gate"
            draft["triggers"] = [{"intent": "QUESTION", "subject": "TIME"}]
            draft["nodes"]["weather_gate"]["gate"] = {
                "type": "pnc:fact",
                "fact": "world.time.week",
                "operator": ">=",
                "value": 1,
            }
            validated = worker.validate_flow(draft)
            self.assertTrue(validated["valid"], validated)

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
