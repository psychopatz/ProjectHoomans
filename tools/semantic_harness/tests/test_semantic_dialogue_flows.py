"""Production-worker acceptance for bounded semantic dialogue flows."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.runner import load_case, run_case
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


FLOW_CASE = (
    Path(__file__).resolve().parents[1]
    / "scenarios"
    / "identity_wellbeing_flow_case.json"
)


class SemanticDialogueFlowTests(unittest.TestCase):
    def test_real_worker_commits_and_resumes_bounded_flows(self) -> None:
        run = run_case(load_case(FLOW_CASE))
        self.assertEqual(run.conflicts, [])
        self.assertEqual(
            [turn["input"] for turn in run.turns],
            ["who are you", "are you okay", "im fine thanks", "My name is Patrick"],
        )

        flows = [turn["result"]["decision"].get("flow") for turn in run.turns]
        self.assertEqual(
            [flow["transition"] for flow in flows],
            ["start", "interrupt_start", "match", "match"],
        )
        self.assertEqual(
            [flow["status"] for flow in flows],
            ["started", "started", "advanced", "retired"],
        )
        self.assertEqual(
            run.turns[0]["contextAfter"]["dialogue"]["flowSessions"][0][
                "active"
            ]["flowId"],
            "identity",
        )
        self.assertEqual(
            run.turns[1]["contextAfter"]["dialogue"]["flowSessions"][0][
                "active"
            ]["flowId"],
            "wellbeing",
        )
        self.assertEqual(
            run.turns[1]["contextAfter"]["dialogue"]["flowSessions"][0][
                "suspended"
            ][0]["flowId"],
            "identity",
        )
        self.assertEqual(
            run.turns[2]["contextAfter"]["dialogue"]["flowSessions"][0][
                "active"
            ]["flowId"],
            "identity",
        )
        self.assertEqual(
            run.turns[3]["contextAfter"]["dialogue"]["flowSessions"],
            [],
        )

    def test_worker_exposes_shared_candidate_flow_and_translation_facts(self) -> None:
        run = run_case(load_case(FLOW_CASE))
        lookup_count = 0
        for turn in run.turns:
            result = turn["result"]
            self.assertEqual(
                result["candidateDiagnostics"]["reason"],
                "eligible_candidate",
            )
            self.assertEqual(
                result["candidates"]["selected"]["patternID"],
                result["candidateDiagnostics"]["selectedPattern"],
            )
            flow = result["decision"]["flow"]
            self.assertEqual(flow["schemaVersion"], 1)
            self.assertIn("flow", result["decision"]["diagnostics"])
            self.assertIn("flowId", flow["diagnostics"])
            lookup_count += len(turn["translation"]["lookups"])
        self.assertGreaterEqual(lookup_count, 1)

    def test_third_modular_greeting_flow_owns_contextual_followup(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {"personality": {"socialStyle": "friendly"}},
                "runtime": {"language": "TL"},
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            opening = worker.input("hello")
            followup = worker.input("thanks")

        opening_observation = opening["observation"]
        self.assertEqual(opening_observation["ir"]["intent"], "GREET")
        self.assertEqual(opening_observation["flow"]["flowId"], "greeting")
        self.assertEqual(opening_observation["flow"]["transition"], "start")
        self.assertEqual(opening_observation["flow"]["status"], "started")
        self.assertEqual(
            opening_observation["flow"]["responsePoolID"],
            "semantic.flow.greeting.opening",
        )
        self.assertEqual(
            opening_observation["response"]["selectionSource"], "flow"
        )
        self.assertEqual(
            opening_observation["response"]["sourceFlowID"], "greeting"
        )
        self.assertEqual(
            opening_observation["response"]["templateID"],
            "semantic.flow.greeting.opening.friendly",
        )
        self.assertTrue(opening_observation["response"]["translated"])
        self.assertEqual(
            opening_observation["response"]["translationKey"],
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly",
        )
        self.assertEqual(len(opening["messages"]), 2)
        self.assertEqual(
            [message["payload"]["planTurn"] for message in opening["messages"]],
            [1, 2],
        )
        self.assertEqual(
            opening["messages"][1]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestionFriendly",
        )
        self.assertTrue(opening_observation["response"]["composed"])
        self.assertEqual(opening_observation["response"]["queueCount"], 2)
        self.assertEqual(opening_observation["response"]["planTurnCount"], 2)
        self.assertTrue(opening_observation["sideEffects"]["none"])

        followup_observation = followup["observation"]
        self.assertEqual(followup_observation["ir"]["intent"], "THANK")
        self.assertEqual(followup_observation["flow"]["flowId"], "greeting")
        self.assertEqual(followup_observation["flow"]["transition"], "match")
        self.assertEqual(followup_observation["flow"]["status"], "retired")
        self.assertEqual(followup_observation["flow"]["activeAfter"], [])
        self.assertEqual(
            followup_observation["flow"]["responsePoolID"],
            "semantic.flow.greeting.followup",
        )
        self.assertEqual(
            followup_observation["response"]["selectionSource"], "flow"
        )
        self.assertEqual(
            followup_observation["response"]["sourceFlowID"], "greeting"
        )
        self.assertEqual(
            followup_observation["response"]["templateID"],
            "semantic.flow.greeting.followup.friendly",
        )
        self.assertTrue(followup_observation["response"]["translated"])
        self.assertGreater(followup_observation["translation"]["lookupCount"], 0)
        self.assertTrue(followup_observation["sideEffects"]["none"])

    def test_composed_flow_plan_renders_and_queues_in_en_and_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                scenario = merge(
                    DEFAULT_SCENARIO,
                    {"runtime": {"language": language}},
                )
                with LuaSemanticWorker(scenario) as worker:
                    opening = worker.input("hello")

                payloads = [message["payload"] for message in opening["messages"]]
                self.assertEqual(len(payloads), 2)
                self.assertEqual(
                    [payload["planTurn"] for payload in payloads],
                    [1, 2],
                )
                self.assertEqual(
                    [payload["planContinuation"] for payload in payloads],
                    ["continue", "await_player"],
                )
                self.assertEqual(
                    payloads[1]["translationKey"],
                    "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion",
                )
                self.assertEqual(
                    payloads[0]["plan"]["sourcePoolID"],
                    "semantic.flow.greeting.opening",
                )
                self.assertEqual(
                    opening["observation"]["response"]["queueCount"],
                    2,
                )
                self.assertEqual(
                    opening["observation"]["response"]["planTurnCount"],
                    2,
                )
                self.assertTrue(opening["observation"]["sideEffects"]["none"])
                if language == "TL":
                    self.assertTrue(all(
                        payload["text"] != payload["fallback"]
                        for payload in payloads
                    ))
                else:
                    self.assertTrue(all(payload["text"] for payload in payloads))

    def test_worker_observation_exposes_real_turn_facts_and_side_effects(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"language": "TL"}},
        )
        with LuaSemanticWorker(scenario) as worker:
            identity = worker.input("who are you")
            wellbeing = worker.input("are you okay")
            status = worker.input("im fine thanks")
            name = worker.input("My name is Patrick")

        first = identity["observation"]
        self.assertEqual(first["ir"]["pattern"], "pnc.question.identity")
        self.assertEqual(first["candidates"]["selectedPattern"], first["ir"]["pattern"])
        self.assertEqual(first["flow"]["flowId"], "identity")
        self.assertEqual(first["flow"]["transition"], "start")
        self.assertEqual(first["flow"]["toNodeId"], "await_player_name")
        self.assertEqual(first["flow"]["activeAfter"][0]["flowId"], "identity")
        self.assertEqual(first["response"]["selectionSource"], "flow")
        self.assertEqual(first["response"]["sourceFlowID"], "identity")
        self.assertEqual(
            first["response"]["sourcePoolID"],
            "semantic.question.identity",
        )
        self.assertEqual(first["response"]["text"], identity["messages"][0]["payload"]["text"])
        self.assertTrue(first["response"]["translated"])
        self.assertEqual(first["translation"]["language"], "TL")
        self.assertGreater(first["translation"]["lookupCount"], 0)
        self.assertTrue(first["sideEffects"]["none"])

        interrupted = wellbeing["observation"]
        self.assertEqual(interrupted["flow"]["transition"], "interrupt_start")
        self.assertEqual(interrupted["flow"]["activeBefore"][0]["flowId"], "identity")
        self.assertEqual(
            interrupted["flow"]["activeAfter"][0]["suspended"][0]["flowId"],
            "identity",
        )
        self.assertEqual(interrupted["response"]["selectionSource"], "flow")
        self.assertEqual(interrupted["response"]["sourceFlowID"], "wellbeing")
        self.assertTrue(interrupted["sideEffects"]["none"])

        resumed = status["observation"]
        self.assertEqual(
            resumed["flow"]["activeAfter"][0]["resumedFlowId"],
            "identity",
        )
        self.assertEqual(resumed["flow"]["transition"], "match")
        self.assertEqual(resumed["flow"]["activeAfter"][0]["flowId"], "identity")
        self.assertNotEqual(resumed["response"].get("selectionSource"), "flow")
        self.assertTrue(resumed["sideEffects"]["none"])

        completed = name["observation"]
        self.assertEqual(completed["flow"]["status"], "retired")
        self.assertEqual(completed["flow"]["activeAfter"], [])
        self.assertNotEqual(completed["response"].get("selectionSource"), "flow")
        self.assertEqual(
            {action["name"] for action in completed["sideEffects"]["actions"]},
            {"SemanticIdentityRequest", "AdjustRelationship"},
        )
        self.assertEqual(
            completed["response"]["text"],
            name["messages"][0]["payload"]["text"],
        )
        self.assertFalse(completed["sideEffects"]["none"])

    def test_response_plan_crosses_real_en_and_tl_presentation(self) -> None:
        for language in ("EN", "TL"):
            scenario = merge(
                DEFAULT_SCENARIO,
                {"runtime": {"language": language}},
            )
            with LuaSemanticWorker(scenario) as worker:
                turn = worker.input("who are you")

            response = turn["result"]["decision"]["response"]
            plan = response["plan"]
            self.assertEqual(plan["schemaVersion"], 1)
            self.assertEqual(plan["kind"], "dialogue_act_plan")
            self.assertEqual(plan["sourcePoolID"], "semantic.question.identity")
            self.assertEqual(
                plan["turns"][0]["segments"][0]["templateID"],
                response["templateID"],
            )
            payload = turn["messages"][0]["payload"]
            self.assertEqual(payload["plan"], plan)
            self.assertEqual(turn["translation"]["language"], language)
            self.assertGreaterEqual(len(turn["translation"]["lookups"]), 1)
            if language == "TL":
                self.assertNotEqual(payload["text"], payload["fallback"])

    def test_real_worker_preview_is_pure_for_flow_interruptions(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("who are you")
            before = worker.snapshot()
            previews = [worker.preview("are you okay") for _ in range(2)]
            after = worker.snapshot()

        for preview in previews:
            self.assertEqual(
                preview["result"]["decision"]["flow"]["transition"],
                "interrupt_start",
            )
            self.assertEqual(preview["contextBefore"], preview["contextAfter"])
            self.assertEqual(preview["messages"], [])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])
            self.assertTrue(preview["observation"]["sideEffects"]["none"])
            self.assertEqual(
                preview["observation"]["flow"]["transition"],
                "interrupt_start",
            )
        self.assertEqual(before["context"], after["context"])
        self.assertEqual(before["transport"], after["transport"])

    def test_wellbeing_refusal_is_a_flow_owned_safe_branch(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("are you okay")
            refusal = worker.input("no")

        flow = refusal["result"]["decision"]["flow"]
        self.assertEqual(flow["transition"], "cancel")
        self.assertEqual(flow["status"], "retired")
        self.assertEqual(
            refusal["contextAfter"]["dialogue"]["flowSessions"],
            [],
        )
        self.assertEqual(refusal["transport"], [])
        self.assertEqual(refusal["toolCalls"], [])
        self.assertEqual(
            refusal["relationshipBefore"], refusal["relationshipAfter"]
        )
