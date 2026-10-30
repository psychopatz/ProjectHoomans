"""C6-C optional-provider parity and non-authorizing fallback."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def provider_scenario(enabled: bool) -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "npc": {
                "healthState": "unknown",
                "needs": {"thirst": 0.9},
                "conditionStats": {},
            },
            "world": {"weather": "rain"},
            "runtime": {
                "llmEnabled": enabled,
                "providerAvailable": enabled,
                "language": "EN",
            },
        },
    )


class ContextualProviderParityC6CTests(unittest.TestCase):
    def test_provider_enabled_reuses_the_same_contextual_plan_and_effects(self) -> None:
        phrases = (
            "Are you okay?",
            "What happened?",
            "Do you need anything?",
            "How many?",
            "I'll get some",
            "Can we talk about the weather",
            "Okay",
        )
        turns: dict[str, list[dict]] = {}
        for label, enabled in (("offline", False), ("provider", True)):
            with LuaSemanticWorker(provider_scenario(enabled)) as worker:
                turns[label] = [worker.input(phrase) for phrase in phrases]

        for offline, provider in zip(turns["offline"], turns["provider"]):
            self.assertEqual(offline["result"]["ir"], provider["result"]["ir"])
            self.assertEqual(
                offline["result"]["decision"]["response"],
                provider["result"]["decision"]["response"],
            )
            self.assertEqual(offline["contextAfter"]["dialogue"], provider["contextAfter"]["dialogue"])
            self.assertEqual(offline["messages"], provider["messages"])
            self.assertEqual(offline["dispatchTransport"], provider["dispatchTransport"])
            self.assertEqual(offline["toolCalls"], provider["toolCalls"])
            self.assertEqual(offline["llmCalls"], 0)
            self.assertEqual(provider["llmCalls"], 0)

    def test_provider_rejection_falls_back_without_authority_or_effects(self) -> None:
        with LuaSemanticWorker(provider_scenario(False)) as offline_worker:
            offline = offline_worker.input("this sentence is not authored")
        with LuaSemanticWorker(provider_scenario(True)) as provider_worker:
            provider = provider_worker.input("this sentence is not authored")

        self.assertEqual(offline["result"]["ir"], provider["result"]["ir"])
        self.assertEqual(offline["result"]["decision"], provider["result"]["decision"])
        self.assertEqual(offline["messages"], provider["messages"])
        self.assertEqual(offline["dispatchTransport"], provider["dispatchTransport"])
        self.assertEqual(offline["toolCalls"], provider["toolCalls"])
        self.assertEqual(offline["llmCalls"], 0)
        self.assertEqual(provider["llmCalls"], 1)
        self.assertTrue(provider["observation"]["sideEffects"]["noGameplayEffects"])
        self.assertIsNone(provider["result"].get("actionResult"))


if __name__ == "__main__":
    unittest.main()
