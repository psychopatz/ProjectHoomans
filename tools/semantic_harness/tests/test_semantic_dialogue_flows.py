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
