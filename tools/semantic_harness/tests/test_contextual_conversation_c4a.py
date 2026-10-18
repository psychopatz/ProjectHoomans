"""C4-A reviewed dataset mapping on the real production Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC4ATests(unittest.TestCase):
    @staticmethod
    def scenario(language: str) -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "needs": {"thirst": 0.9},
                    "conditionStats": {},
                },
                "runtime": {"language": language},
            },
        )

    def test_reviewed_promise_mapping_is_localized_and_non_dispatching(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(self.scenario(language)) as worker:
                    worker.input("Do you need anything?")
                    worker.input("How many?")
                    turn = worker.input("I'll pick some up")

                result = turn["result"]
                ir = result["ir"]
                response = result["decision"]["response"]
                plan = response["plan"]

                self.assertTrue(turn["accepted"], turn.get("reason"))
                self.assertEqual(ir["intent"], "PROMISE")
                self.assertEqual(ir["speechAct"], "PROMISE")
                self.assertEqual(ir["subject"], "NEEDS")
                self.assertIsNone(ir.get("action"))
                self.assertEqual(
                    ir["provenance"]["pattern"],
                    "pnc.dataset.promise.needs.i_ll_pick_some_up",
                )
                self.assertEqual(
                    response["templateID"],
                    "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                )
                self.assertEqual(plan["dialogueAct"], "PROMISE_ACKNOWLEDGEMENT")
                self.assertEqual(plan["topic"], "NEEDS")
                self.assertEqual(plan["uncertainty"], "pending")
                self.assertEqual(plan["groundedFactRefs"], ["npc.needs.thirst"])
                self.assertEqual(turn["translation"]["language"], language)
                self.assertEqual(
                    turn["messages"][0]["payload"]["translationKey"],
                    "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                )
                self.assertTrue(turn["messages"][0]["payload"]["text"])
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(turn["llmCalls"], 0)
                self.assertTrue(turn["observation"]["sideEffects"]["none"])

    def test_reviewed_negative_does_not_become_a_promise_or_command(self) -> None:
        with LuaSemanticWorker(self.scenario("EN")) as worker:
            worker.input("Do you need anything?")
            worker.input("How many?")
            turn = worker.input("I won't pick some up")

        ir = turn["result"]["ir"]
        self.assertIsNone(ir.get("intent"))
        self.assertIsNone(ir.get("action"))
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
