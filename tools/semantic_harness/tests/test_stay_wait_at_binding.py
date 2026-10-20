"""Real-Lua Semantic Lab acceptance for STAY versus WAIT_AT ownership."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class StayWaitAtBindingTests(unittest.TestCase):
    def test_live_catalog_distinguishes_command_and_task_bindings(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            actions = {
                row["id"]: row for row in worker.flow_catalog()["actionCatalog"]
            }

        stay = actions["STAY"]
        self.assertTrue(stay["recognized"])
        self.assertTrue(stay["dispatchable"])
        self.assertEqual(stay["binding"]["id"], "pnc:companion.stay")
        self.assertEqual(stay["binding"]["commandID"], "stay")
        self.assertEqual(
            stay["binding"]["handlerID"], "PNC.Client.SendCompanionCommand"
        )
        self.assertEqual(stay["binding"]["route"], "existing_companion_command")

        wait_at = actions["WAIT_AT"]
        self.assertTrue(wait_at["recognized"])
        self.assertTrue(wait_at["dispatchable"])
        self.assertEqual(wait_at["binding"]["id"], "pnc:task.wait_at")
        self.assertEqual(
            wait_at["binding"]["handlerID"], "PNC.Client.RequestSemanticTask"
        )
        self.assertEqual(wait_at["binding"]["route"], "existing_semantic_task")

    def test_stay_and_wait_at_use_distinct_real_lua_routes(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            previews = [worker.preview("Wait at the campfire") for _ in range(2)]
            stay = worker.input("Stay here")
            wait_at = worker.input("Wait at the campfire")
            wait_at_reference = worker.input("Wait there")
            stay_at_reference = worker.input("Stay there")
            unresolved = worker.input("stay at the recycle bin")
            question = worker.input("Are you waiting at the campfire?")

        for preview in previews:
            self.assertEqual(preview["observation"]["ir"]["action"], "WAIT_AT")
            self.assertEqual(
                preview["observation"]["capabilityBinding"]["id"],
                "pnc:task.wait_at",
            )
            self.assertTrue(preview["observation"]["sideEffects"]["none"])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])

        stay_result = stay["result"]
        self.assertEqual(stay_result["ir"]["action"], "STAY")
        self.assertEqual(
            stay_result["ir"]["provenance"]["pattern"], "pnc.command.wait"
        )
        self.assertEqual(stay_result["actionResult"]["commandID"], "stay")
        self.assertEqual(
            stay_result["actionResult"]["capabilityID"], "pnc:companion.stay"
        )
        self.assertEqual(
            stay["transport"][0]["command"], "CompanionCommand"
        )
        self.assertNotIn(
            "SemanticTaskRequest", [event["command"] for event in stay["transport"]]
        )
        self.assertEqual(
            stay["messages"][0]["payload"]["text"],
            "Okay, I'll stay.",
        )

        wait_result = wait_at["result"]
        self.assertEqual(wait_result["ir"]["action"], "WAIT_AT")
        self.assertEqual(
            wait_result["ir"]["provenance"]["pattern"], "pnc.command.wait_at"
        )
        self.assertTrue(wait_result["actionResult"]["accepted"])
        self.assertEqual(
            wait_result["actionResult"]["capabilityID"], "pnc:task.wait_at"
        )
        self.assertEqual(
            wait_result["actionResult"]["handlerID"],
            "PNC.Client.RequestSemanticTask",
        )
        self.assertEqual(
            wait_result["actionResult"]["request"]["target"]["category"],
            "CAMPFIRE",
        )
        self.assertEqual(
            wait_result["actionResult"]["details"]["status"], "admitted"
        )
        self.assertEqual(
            wait_at["transport"][0]["command"], "SemanticTaskRequest"
        )
        self.assertNotIn(
            "CompanionCommand",
            [event["command"] for event in wait_at["transport"]],
        )
        self.assertTrue(wait_at["result"]["flow"]["generated"])
        self.assertEqual(
            wait_at["result"]["flow"]["workflowKind"], "parameterized_task"
        )
        self.assertEqual(
            wait_at["messages"][0]["payload"]["text"], "Okay, I'll wait there."
        )

        for reference_turn in (wait_at_reference, stay_at_reference):
            reference_result = reference_turn["result"]
            self.assertEqual(
                reference_result["ir"]["provenance"]["pattern"],
                "pnc.command.wait_at_reference",
            )
            self.assertEqual(reference_result["ir"]["action"], "WAIT_AT")
            self.assertTrue(reference_result["actionResult"]["accepted"])
            self.assertEqual(
                reference_result["actionResult"]["request"]["target"]["category"],
                "CAMPFIRE",
            )
            self.assertEqual(
                reference_turn["messages"][0]["payload"]["text"],
                "Okay, I'll wait there.",
            )
            self.assertEqual(
                reference_turn["transport"][0]["command"],
                "SemanticTaskRequest",
            )
            self.assertTrue(
                reference_result["ir"]["diagnostics"]["contextResolved"]
            )

        unresolved_result = unresolved["result"]
        self.assertFalse(unresolved_result["actionResult"]["accepted"])
        self.assertEqual(
            unresolved_result["actionResult"]["reason"], "target_unresolved"
        )
        self.assertEqual(
            unresolved["messages"][0]["payload"]["text"],
            "I can't find that place nearby.",
        )
        self.assertEqual(
            unresolved["transport"][0]["command"], "SemanticTaskRequest"
        )

        self.assertEqual(
            question["result"]["decision"]["branch"], "ASK_CLARIFICATION"
        )
        self.assertEqual(question["transport"], [])
        self.assertEqual(question["toolCalls"], [])

    def test_unresolved_location_reference_cannot_dispatch(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            turn = worker.input("Wait there")

        result = turn["result"]
        self.assertEqual(
            result["ir"]["provenance"]["pattern"],
            "pnc.command.wait_at_reference",
        )
        self.assertTrue(result["ir"]["diagnostics"]["unresolvedEntity"])
        self.assertFalse(result["actionResult"]["accepted"])
        self.assertEqual(
            result["actionResult"]["reason"], "clarification_required"
        )
        self.assertEqual(
            turn["messages"][0]["payload"]["text"],
            "I can't wait there right now.",
        )
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"][0]["reason"], "clarification_required")


if __name__ == "__main__":
    unittest.main()
