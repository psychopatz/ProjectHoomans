"""Fresh-worker acceptance for the compiler-generated FOLLOW definition."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class SemanticAuthoringCompilerWorkerTests(unittest.TestCase):
    def test_generated_definition_loads_routes_and_survives_restart(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            self.assertIn(
                "pnc.dialogue.follow.flow",
                [flow["id"] for flow in catalog["flows"]],
            )
            previews = [worker.preview("Keep close behind me") for _ in range(2)]
            first = worker.input("Keep close behind me")
            negative = worker.input("Don't keep close behind me")
            question = worker.input("Are you keeping close behind me")
            worker.restart()
            after_restart = worker.input("Please keep close behind me")

        for preview in previews:
            self.assertEqual(
                preview["observation"]["ir"]["pattern"],
                "pnc.dialogue.follow.keep_close_behind_me",
            )
            self.assertTrue(preview["observation"]["sideEffects"]["none"])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])

        result = first["result"]
        self.assertEqual(
            result["ir"]["provenance"]["pattern"],
            "pnc.dialogue.follow.keep_close_behind_me",
        )
        self.assertEqual(result["ir"]["action"], "FOLLOW")
        self.assertEqual(result["actionResult"]["capabilityID"], "pnc:companion.follow")
        self.assertEqual([event["command"] for event in first["transport"]], ["CompanionCommand"])
        self.assertEqual(first["transport"][0]["payload"]["commandID"], "follow")

        for safe_negative in (negative, question):
            self.assertEqual(safe_negative["transport"], [])
            self.assertEqual(safe_negative["toolCalls"], [])
            self.assertTrue(safe_negative["observation"]["sideEffects"]["none"])
        self.assertEqual(negative["result"]["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertEqual(question["result"]["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertEqual(
            after_restart["result"]["ir"]["provenance"]["pattern"],
            "pnc.dialogue.follow.please_keep_close_behind_me",
        )
        self.assertEqual(after_restart["result"]["actionResult"]["commandID"], "follow")


if __name__ == "__main__":
    unittest.main()
