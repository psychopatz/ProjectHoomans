"""C4-B reviewed SGD-style clarification on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC4BTests(unittest.TestCase):
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

    def test_reviewed_clarification_keeps_quantity_obligation_open_en_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(self.scenario(language)) as worker:
                    worker.input("Do you need anything?")
                    turn = worker.input("Which item do you mean")

                result = turn["result"]
                ir = result["ir"]
                response = result["decision"]["response"]
                plan = response["plan"]
                pending = turn["contextAfter"]["dialogue"]["pendingFollowUp"]

                self.assertEqual(ir["intent"], "CLARIFY")
                self.assertEqual(ir["speechAct"], "CLARIFY")
                self.assertEqual(ir["subject"], "NEEDS")
                self.assertEqual(
                    ir["provenance"]["pattern"],
                    "pnc.dataset.clarify.needs.which_item_do_you_mean",
                )
                self.assertEqual(turn["observation"]["flow"]["transition"], "match")
                self.assertEqual(turn["observation"]["flow"]["toNodeId"], "clarification")
                self.assertEqual(
                    response["templateID"],
                    "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                )
                self.assertEqual(plan["dialogueAct"], "ASK_CLARIFICATION")
                self.assertEqual(plan["topic"], "NEEDS")
                self.assertEqual(plan["uncertainty"], "ambiguous")
                self.assertEqual(plan["groundedFactRefs"], ["npc.needs.thirst"])
                self.assertEqual(pending["status"], "open")
                self.assertEqual(pending["requiredSlots"], ["quantity"])
                self.assertEqual(turn["translation"]["language"], language)
                self.assertTrue(turn["messages"][0]["payload"]["text"])
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(turn["llmCalls"], 0)
                self.assertTrue(turn["observation"]["sideEffects"]["none"])

    def test_nearby_negative_abstains_without_dispatch(self) -> None:
        with LuaSemanticWorker(self.scenario("EN")) as worker:
            worker.input("Do you need anything?")
            turn = worker.input("Which items do you mean")

        ir = turn["result"]["ir"]
        self.assertIsNone(ir.get("intent"))
        self.assertIsNone(ir.get("action"))
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
