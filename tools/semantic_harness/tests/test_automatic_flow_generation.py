"""G0A acceptance for metadata-driven simple-command flow generation."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class AutomaticFlowGenerationTests(unittest.TestCase):
    def test_live_coverage_generates_follow_and_stay_from_one_template(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            coverage = worker.flow_coverage()
            capabilities = worker.capabilities()

        generation = catalog["generation"]
        self.assertEqual(generation["templateVersion"], 1)
        self.assertIn("simple_command:v1", generation["templateFingerprint"])
        self.assertEqual(generation["summary"]["generated"], 2)
        self.assertEqual(generation["summary"]["metadata_incomplete"], 0)
        rows = {
            row["id"]: row for row in generation["coverage"]
        }
        self.assertEqual(rows["FOLLOW"]["classification"], "generated")
        self.assertEqual(rows["STAY"]["classification"], "generated")
        self.assertTrue(rows["WAIT_AT"]["reason"])
        self.assertEqual(rows["WAIT_AT"]["classification"], "unsupported_workflow")
        self.assertEqual(
            {row["id"] for row in coverage},
            set(rows),
        )
        manifest_roles = {
            module["role"]: module["path"]
            for module in capabilities["moduleManifest"]
            if module.get("role") in {
                "semantic_generation_manifest", "semantic_generated_flows",
            }
        }
        self.assertIn("PNC_SemanticAutomaticFlowManifest.lua", manifest_roles["semantic_generation_manifest"])
        self.assertIn("PNC_SemanticGeneratedAutomaticFlows.lua", manifest_roles["semantic_generated_flows"])

        flows = {
            flow["id"]: flow
            for flow in catalog["flows"]
            if flow.get("workflowKind") == "simple_command"
        }
        self.assertEqual(len(flows), 2)
        follow = flows[rows["FOLLOW"]["flowID"]]
        stay = flows[rows["STAY"]["flowID"]]
        self.assertEqual(set(follow["nodes"]), set(stay["nodes"]))
        self.assertEqual(follow["templateVersion"], stay["templateVersion"])
        for flow in (follow, stay):
            action = flow["nodes"]["request"]["action"]
            self.assertEqual(action["dispatchCount"], 1)
            self.assertEqual(
                set(action["resultTransitions"]),
                {"accepted", "failed", "network_queued", "pending", "queued", "rejected"},
            )
            self.assertEqual(
                set(action["resultTransitions"].values()),
                {"queued", "rejected", "failed"},
            )

    def test_real_worker_records_result_nodes_and_one_dispatch(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            follow = worker.input("Follow me")
            stay = worker.input("Stay here")

        for result, action, response_key in (
            (follow, "follow", "UI_PNC_Conversation_Semantic_GeneratedFollowQueued"),
            (stay, "stay", "UI_PNC_Conversation_Semantic_GeneratedStayQueued"),
        ):
            flow = result["result"]["flow"]
            self.assertTrue(flow["generated"])
            self.assertEqual(flow["resultOutcome"], "queued")
            self.assertEqual(flow["resultNodeId"], "queued")
            self.assertEqual(flow["dispatchCount"], 1)
            self.assertEqual(result["result"]["actionResult"]["status"], "accepted")
            self.assertEqual(result["result"]["actionResult"]["commandID"], action)
            self.assertEqual(len(result["transport"]), 1)
            self.assertEqual(result["messages"][0]["payload"]["translationKey"], response_key)

    def test_denied_failed_and_context_gate_are_truthful(self) -> None:
        denied_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"commandResponses": {
                "follow": {"accepted": False, "reason": "unauthorized_companion"},
            }}},
        )
        failed_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"commandResponses": {
                "follow": {
                    "accepted": False,
                    "reason": "transport_failed",
                    "details": {"status": "failed"},
                },
            }}},
        )
        gated_scenario = merge(
            DEFAULT_SCENARIO,
            {"conversation": {"semanticAuthorization": {"authorized": False}}},
        )
        with LuaSemanticWorker(denied_scenario) as worker:
            denied = worker.input("Follow me")
        with LuaSemanticWorker(failed_scenario) as worker:
            failed = worker.input("Follow me")
        with LuaSemanticWorker(gated_scenario) as worker:
            gated = worker.input("Follow me")

        self.assertEqual(denied["result"]["flow"]["resultNodeId"], "rejected")
        self.assertEqual(denied["messages"][0]["payload"]["text"], "I can't follow you right now.")
        self.assertEqual(failed["result"]["flow"]["resultNodeId"], "failed")
        self.assertEqual(failed["messages"][0]["payload"]["text"], "I couldn't start following you.")
        self.assertEqual(gated["result"]["flow"]["toNodeId"], "rejected")
        self.assertEqual(gated["result"]["actionResult"]["status"], "semantic_dispatch_blocked")
        self.assertEqual(gated["transport"], [])
        self.assertEqual(gated["messages"][0]["payload"]["text"], "I can't follow you right now.")

    def test_preview_is_pure_and_generation_survives_restart(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            first = worker.preview("Follow me")
            second = worker.preview("Follow me")
            generated = worker.generate_flows()
            worker.restart()
            after_restart = worker.flow_catalog()

        for preview in (first, second):
            self.assertTrue(preview["result"]["flow"]["generated"])
            self.assertEqual(preview["result"]["flow"]["toNodeId"], "request")
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["messages"], [])
        self.assertEqual(
            generated["generation"]["templateFingerprint"],
            after_restart["generation"]["templateFingerprint"],
        )
        self.assertEqual(
            generated["generation"]["generatedFlowIDs"],
            after_restart["generation"]["generatedFlowIDs"],
        )


if __name__ == "__main__":
    unittest.main()
