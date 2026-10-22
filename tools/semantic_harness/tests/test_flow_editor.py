"""Semantic Lab flow editor contracts against the production Lua registry."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.ui.flow_editor.pane import (
    coverage_lines,
    coverage_summary,
    flow_display_name,
    flow_graph_model,
    graph_render_mode,
)
from tools.semantic_harness.codebuilder.interaction_explorer import (
    interaction_summary,
    search_interactions,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.flow_editor.model import (
    conversation_graph_diagnostics,
    conversation_graph_model,
)


class FlowEditorTests(unittest.TestCase):
    def test_generated_flow_labels_hide_registry_prefix_but_keep_meaning(self) -> None:
        self.assertEqual(
            flow_display_name(
                "pnc.generated.simple_command.pnc.quest.clinic.supplies.accept",
                {
                    "id": "pnc.generated.simple_command.pnc.quest.clinic.supplies.accept",
                    "workflowKind": "simple_command",
                    "capabilityID": "pnc:quest.clinic_supplies.accept",
                },
            ),
            "Quest / Clinic Supplies / Accept",
        )
        self.assertEqual(
            flow_display_name("pnc.generated.parameterized_task.pnc.task.wait.at"),
            "Task / Wait / At",
        )
        self.assertEqual(flow_display_name("greeting"), "greeting")
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
        wait_at = next(
            flow for flow in catalog["flows"]
            if flow["id"] == "pnc.generated.parameterized_task.pnc.task.wait.at"
        )
        self.assertEqual(flow_display_name(wait_at["id"], wait_at), "Task / Wait At")

    def test_graph_render_mode_reduces_detail_before_labels_overlap(self) -> None:
        self.assertEqual(graph_render_mode(0.39), "overview")
        self.assertEqual(graph_render_mode(0.65), "compact")
        self.assertEqual(graph_render_mode(1.0), "detail")

    def test_conversation_graph_adapter_preserves_runtime_states_and_labels(self) -> None:
        graph = conversation_graph_model(
            {
                "graphID": "conversation_block:test",
                "blockID": "test",
                "categoryID": "projecthoomans:test",
                "entryNodeID": "opening",
                "currentNodeID": "opening",
                "nodes": [
                    {
                        "id": "opening",
                        "title": "opening",
                        "npcText": "Authored opening",
                        "state": "current",
                        "choices": [
                            {"id": "detail", "text": "Ask for details", "enabled": True}
                        ],
                    },
                    {
                        "id": "details",
                        "title": "details",
                        "npcText": "Authored details",
                        "state": "available",
                        "choices": [],
                    },
                ],
                "edges": [
                    {
                        "fromNodeID": "opening",
                        "toNodeID": "details",
                        "choiceID": "detail",
                        "label": "Ask for details",
                        "state": "available",
                        "clickable": True,
                    },
                    {
                        "fromNodeID": "opening",
                        "toNodeID": "$root",
                        "choiceID": "leave",
                        "label": "Leave",
                        "state": "root_exit",
                    },
                ],
            }
        )
        self.assertEqual(graph["graphKind"], "conversation_block")
        self.assertEqual(graph["initial"], "opening")
        self.assertEqual(
            {node["state"] for node in graph["nodes"]},
            {"current", "available"},
        )
        detail_edge = next(edge for edge in graph["edges"] if edge["choiceID"] == "detail")
        self.assertTrue(detail_edge["internal"])
        self.assertTrue(detail_edge["clickable"])
        self.assertEqual(detail_edge["label"], "Ask for details")
        self.assertFalse(
            next(edge for edge in graph["edges"] if edge["choiceID"] == "leave")["internal"]
        )

    def test_conversation_graph_diagnostics_exposes_keys_and_suspicious_content(self) -> None:
        diagnostics = conversation_graph_diagnostics(
            {
                "graphID": "conversation_block:test",
                "blockID": "test",
                "categoryID": "projecthoomans:test",
                "source": {"domain": "pnc.test", "pathPattern": "test/{language}.json"},
                "sourceIDs": {"nodeID": "opening"},
                "nodes": [
                    {
                        "id": "opening",
                        "textKey": "node.opening",
                        "npcText": "May mga tracks around here today.",
                        "source": {"blockID": "test", "nodeID": "opening"},
                        "choices": [
                            {
                                "id": "detail",
                                "textKey": "choice.detail",
                                "text": "Ask for details",
                                "enabled": True,
                                "outcomeIDs": ["open", "guarded"],
                                "nextNodeTargets": ["details"],
                            }
                        ],
                    }
                ],
            }
        )
        self.assertEqual(diagnostics["source"]["domain"], "pnc.test")
        self.assertEqual(diagnostics["nodes"][0]["translationKey"], "node.opening")
        self.assertEqual(diagnostics["choices"][0]["outcomeIDs"], ["open", "guarded"])
        self.assertTrue(
            any("mixed_language_markers" in row["reasons"] for row in diagnostics["suspicious"])
        )

    def test_graph_model_exposes_nodes_and_transition_edges(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        greeting = next(flow for flow in catalog["flows"] if flow["id"] == "greeting")
        graph = flow_graph_model(greeting)
        self.assertEqual(graph["flowID"], "greeting")
        self.assertEqual(graph["initial"], "await_thanks")
        self.assertFalse(graph["generated"])
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
        await_thanks = next(
            node for node in graph["nodes"] if node["id"] == "await_thanks"
        )
        self.assertEqual(
            await_thanks["branchOffers"][0]["id"],
            "greeting.thanks",
        )

    def test_generated_graph_exposes_typed_action_and_result_edges(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        follow = next(
            flow for flow in catalog["flows"]
            if flow["id"] == "pnc.generated.simple_command.pnc.companion.follow"
        )
        graph = flow_graph_model(follow)
        self.assertTrue(graph["generated"])
        self.assertEqual(graph["workflowKind"], "simple_command")
        self.assertEqual(graph["capabilityID"], "pnc:companion.follow")
        request = next(node for node in graph["nodes"] if node["id"] == "request")
        self.assertEqual(request["action"]["capabilityID"], "pnc:companion.follow")
        self.assertEqual(request["action"]["dispatchCount"], 1)
        self.assertEqual(
            {
                outcome: request["resultTransitions"][outcome]
                for outcome in ("queued", "rejected", "failed")
            },
            {"queued": "queued", "rejected": "rejected", "failed": "failed"},
        )
        self.assertEqual(
            {
                (edge["field"], edge["toNodeID"])
                for edge in graph["edges"]
                if edge["fromNodeID"] == "request"
                and edge["field"].startswith("result:")
                and edge["field"] in {"result:queued", "result:rejected", "result:failed"}
            },
            {
                ("result:queued", "queued"),
                ("result:rejected", "rejected"),
                ("result:failed", "failed"),
            },
        )

    def test_semantic_lab_coverage_view_keeps_exact_live_reasons(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        coverage = catalog["generation"]["coverage"]
        summary = coverage_summary(coverage)
        lines = coverage_lines(coverage)
        self.assertEqual(sum(summary.values()), 18)
        self.assertEqual(summary["generated"], 17)
        self.assertEqual(summary.get("unsupported_workflow", 0), 0)
        self.assertTrue(
            any(line.startswith("GIFT: generated") for line in lines)
        )
        self.assertTrue(any(line.startswith("CAMP: generated") for line in lines))
        self.assertTrue(any(line.startswith("HELP: generated") for line in lines))

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

    def test_interaction_explorer_searches_live_policy_flows_and_core_routes(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        policy = catalog["policyCatalog"]
        hostile = next(
            branch for branch in policy["branches"]
            if branch["id"] == "HOSTILE_REMARK_RECEIVED"
        )
        self.assertIn("pnc.social.insult", hostile["triggerIDs"])
        self.assertIn("pnc.social.threaten", next(
            branch for branch in policy["branches"]
            if branch["id"] == "THREAT_RECEIVED"
        )["triggerIDs"])
        self.assertTrue(catalog["responsePoolCatalog"])

        insult = search_interactions(catalog, "INSULT", limit=128)
        insult_summary = interaction_summary(insult)
        self.assertGreaterEqual(insult_summary["policy_branch"], 1)
        self.assertGreaterEqual(insult_summary["trigger"], 1)
        hostile_row = next(
            row for row in insult
            if row.get("id") == "policy:HOSTILE_REMARK_RECEIVED"
        )
        self.assertIn("directed social authority / transport", hostile_row["routeSteps"])

        follow = search_interactions(catalog, "FOLLOW", limit=128)
        self.assertTrue(any(row.get("kind") == "flow" for row in follow))
        self.assertTrue(any(row.get("kind") == "capability" for row in follow))
        self.assertTrue(any(row.get("kind") == "generated" for row in follow))

        needs = search_interactions(catalog, "NEEDS", limit=128)
        self.assertTrue(any(row.get("kind") == "flow" for row in needs))
        self.assertTrue(any(row.get("kind") == "trigger" for row in needs))
        self.assertTrue(any(row.get("kind") == "policy_branch" for row in needs))

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
            [
                "identity",
                "wellbeing",
                "needs",
                "weather_context",
                "greeting",
                "pnc.dialogue.follow.flow",
                "pnc.lab.stay_with_you.flow",
                "pnc.generated.parameterized_task.pnc.task.consume",
                "pnc.generated.parameterized_task.pnc.task.drink",
                "pnc.generated.parameterized_task.pnc.task.eat",
                "pnc.generated.parameterized_task.pnc.task.fetch",
                "pnc.generated.parameterized_task.pnc.task.give",
                "pnc.generated.parameterized_task.pnc.task.refill",
                "pnc.generated.parameterized_task.pnc.task.wait.at",
                "pnc.generated.simple_command.pnc.companion.camp",
                "pnc.generated.simple_command.pnc.companion.follow",
                "pnc.generated.simple_command.pnc.companion.go.home",
                "pnc.generated.simple_command.pnc.companion.stay",
                "pnc.generated.simple_command.pnc.companion.stop",
                "pnc.generated.simple_command.pnc.quest.clinic.supplies.accept",
                "pnc.generated.simple_command.pnc.quest.clinic.supplies.offer",
                "pnc.generated.simple_command.pnc.quest.clinic.supplies.status",
                "pnc.generated.simple_command.pnc.quest.clinic.supplies.turn.in",
                "pnc.generated.multi_stage_gift.pnc.gift.offer",
                ],
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
            draft["nodes"]["await_thanks"]["branchOffers"] = [
                {
                    "id": "lab.compliment.thanks",
                    "labelKey": "UI_Lab_Compliment_Thanks_Label",
                    "labelFallback": "Thank them",
                    "utteranceKey": "UI_Lab_Compliment_Thanks_Utterance",
                    "utteranceFallback": "Thanks.",
                    "frame": {
                        "intent": "THANK",
                        "speechAct": "THANK",
                    },
                    "constraints": {
                        "all": [
                            {
                                "path": "ir.intent",
                                "op": "eq",
                                "value": "COMPLIMENT",
                            },
                            {
                                "not": {
                                    "path": "npcState.activeBehavior",
                                    "op": "eq",
                                    "value": "busy",
                                },
                            },
                        ],
                    },
                },
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
            offer = next(
                item
                for item in opening["observation"]["suggestions"]["candidates"]
                if item["id"] == "lab.compliment.thanks"
            )
            self.assertEqual(offer["source"]["kind"], "active_flow")
            self.assertEqual(offer["eligibility"]["status"], "allowed")
            self.assertTrue(
                any(
                    row.get("candidateID") == "lab.compliment.thanks"
                    and row.get("status") == "allowed"
                    for row in opening["observation"]["suggestions"]["predicateTrace"]
                )
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
