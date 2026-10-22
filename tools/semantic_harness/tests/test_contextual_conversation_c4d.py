"""C4-D reviewed causal wellbeing follow-up on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualConversationC4DTests(unittest.TestCase):
    @staticmethod
    def scenario(language: str) -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "unknown",
                    "needs": {},
                    "conditionStats": {},
                },
                "runtime": {"language": language},
            },
        )

    def test_reviewed_causal_followup_stays_unknown_and_truthful_en_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(self.scenario(language)) as worker:
                    worker.input("Are you okay?")
                    turn = worker.input("What is going on with you")

                ir = turn["result"]["ir"]
                response = turn["result"]["decision"]["response"]
                plan = response["plan"]

                self.assertEqual(ir["intent"], "QUESTION")
                self.assertEqual(ir["speechAct"], "QUESTION")
                self.assertEqual(ir["subject"], "WELLBEING")
                self.assertEqual(
                    ir["provenance"]["pattern"],
                    "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                )
                self.assertEqual(
                    ir["diagnostics"]["candidateSelection"]["selectedPattern"],
                    "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                )
                self.assertEqual(
                    response["templateID"],
                    "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                )
                self.assertEqual(plan["dialogueAct"], "ASK_CLARIFICATION")
                self.assertEqual(plan["topic"], "WELLBEING")
                self.assertEqual(plan["uncertainty"], "unknown")
                self.assertEqual(plan["groundedFactRefs"], [])
                self.assertIn("do not know what caused it", turn["messages"][0]["payload"]["fallback"])
                self.assertEqual(turn["translation"]["language"], language)
                self.assertTrue(turn["messages"][0]["payload"]["text"])
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(turn["llmCalls"], 0)
                self.assertTrue(turn["observation"]["sideEffects"]["none"])

    def test_nearby_first_person_negative_abstains_without_dispatch(self) -> None:
        with LuaSemanticWorker(self.scenario("EN")) as worker:
            turn = worker.input("What is going on with me")

        self.assertIsNone(turn["result"]["ir"].get("intent"))
        self.assertIsNone(turn["result"]["ir"].get("action"))
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
