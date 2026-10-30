"""Phase 5 optional-provider parity probes on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SemanticProviderParityTests(unittest.TestCase):
    @staticmethod
    def scenario(*, enabled: bool) -> dict:
        return merge(DEFAULT_SCENARIO, {
            "runtime": {
                "llmEnabled": enabled,
                "providerAvailable": enabled,
            },
        })

    def test_authorized_local_command_is_provider_parity(self) -> None:
        turns = {}
        for label, enabled in (("disabled", False), ("enabled", True)):
            with LuaSemanticWorker(self.scenario(enabled=enabled)) as worker:
                turns[label] = worker.input("follow me")

        for label, turn in turns.items():
            with self.subTest(provider=label):
                self.assertTrue(turn["accepted"], turn.get("reason"))
                result = turn["result"]
                self.assertEqual(result["ir"]["intent"], "REQUEST")
                self.assertEqual(result["ir"]["action"], "FOLLOW")
                self.assertEqual(
                    result["decision"]["branch"], "COMMAND_ACCEPTED"
                )
                self.assertEqual(result["decision"]["route"], "deterministic")
                self.assertEqual(result["actionResult"]["commandID"], "follow")
                self.assertTrue(result["actionResult"]["accepted"])
                self.assertEqual(turn["llmCalls"], 0)
                self.assertEqual(len(turn["dispatchTransport"]), 1)
                self.assertEqual(len(turn["toolCalls"]), 1)
                self.assertEqual(
                    turn["relationshipBefore"], turn["relationshipAfter"]
                )

        self.assertEqual(
            turns["disabled"]["result"]["ir"]["provenance"]["pattern"],
            turns["enabled"]["result"]["ir"]["provenance"]["pattern"],
        )
        self.assertEqual(
            turns["disabled"]["result"]["actionResult"],
            turns["enabled"]["result"]["actionResult"],
        )

    def test_provider_fallback_is_safe_when_provider_is_available(self) -> None:
        turns = {}
        for label, enabled in (("disabled", False), ("enabled", True)):
            with LuaSemanticWorker(self.scenario(enabled=enabled)) as worker:
                turns[label] = worker.input("this sentence is not authored")

        for label, turn in turns.items():
            with self.subTest(provider=label):
                self.assertTrue(turn["accepted"], turn.get("reason"))
                result = turn["result"]
                self.assertEqual(
                    result["decision"]["branch"], "ASK_CLARIFICATION"
                )
                self.assertEqual(result["decision"]["route"], "deterministic")
                self.assertIsNone(result.get("actionResult"))
                self.assertEqual(turn["dispatchTransport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(
                    turn["relationshipBefore"], turn["relationshipAfter"]
                )

        self.assertEqual(turns["disabled"]["llmCalls"], 0)
        self.assertEqual(turns["enabled"]["llmCalls"], 1)


if __name__ == "__main__":
    unittest.main()
