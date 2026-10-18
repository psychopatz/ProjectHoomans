"""C3-B needs quantity follow-up on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC3BTests(unittest.TestCase):
    @staticmethod
    def scenario(language: str, needs: dict) -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "needs": needs,
                    "conditionStats": {},
                },
                "runtime": {"language": language},
            },
        )

    def test_needs_question_opens_quantity_obligation_and_resolves_en_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(
                    self.scenario(language, {"hunger": 0.9})
                ) as worker:
                    first = worker.input("Do you need anything?")
                    second = worker.input("How many?")

                first_ir = first["result"]["ir"]
                first_response = first["result"]["decision"]["response"]
                first_plan = first_response["plan"]
                pending = first["contextAfter"]["dialogue"]["pendingFollowUp"]
                self.assertTrue(first["accepted"], first.get("reason"))
                self.assertEqual(first_ir["subject"], "NEEDS")
                self.assertEqual(
                    first_ir["provenance"]["pattern"],
                    "pnc.question.needs_offer_plain",
                )
                self.assertEqual(
                    first_response["templateID"],
                    "semantic.question.needs.offer.hunger",
                )
                self.assertEqual(first_plan["dialogueAct"], "NEEDS_REPORT")
                self.assertEqual(first_plan["topic"], "NEEDS")
                self.assertEqual(
                    first_plan["groundedFactRefs"], ["npc.needs.hunger"]
                )
                self.assertEqual(first_plan["uncertainty"], "known")
                self.assertEqual(pending["topic"], "needs")
                self.assertEqual(pending["requiredSlots"], ["quantity"])
                self.assertEqual(pending["sourceFactRefs"], ["npc.needs"])
                self.assertEqual(
                    first["observation"]["flow"]["transition"], "start"
                )
                self.assertEqual(
                    first["observation"]["flow"]["responsePoolID"],
                    "semantic.question.needs.offer",
                )
                self.assertEqual(first["translation"]["language"], language)
                self.assertTrue(first["messages"][0]["payload"]["text"])

                second_ir = second["result"]["ir"]
                second_response = second["result"]["decision"]["response"]
                second_plan = second_response["plan"]
                after = second["contextAfter"]["dialogue"]
                self.assertEqual(second_ir["subject"], "QUANTITY")
                self.assertEqual(
                    second_ir["provenance"]["pattern"],
                    "pnc.question.quantity_follow_up",
                )
                self.assertEqual(
                    second_response["templateID"],
                    "semantic.question.needs.quantity.hunger",
                )
                self.assertEqual(second_plan["dialogueAct"], "NEEDS_QUANTITY")
                self.assertEqual(second_plan["uncertainty"], "pending")
                self.assertEqual(
                    second_plan["groundedFactRefs"], ["npc.needs.hunger"]
                )
                pending_after_quantity = after["pendingFollowUp"]
                self.assertEqual(pending_after_quantity["kind"], "PROPOSAL")
                self.assertEqual(
                    pending_after_quantity["requiredSlots"], ["offer"]
                )
                self.assertEqual(after["lastFollowUp"]["status"], "fulfilled")
                self.assertEqual(
                    after["lastFollowUp"]["requiredSlots"], ["quantity"]
                )
                self.assertEqual(
                    second["observation"]["flow"]["transition"], "match"
                )
                self.assertEqual(second["translation"]["language"], language)
                self.assertTrue(second["messages"][0]["payload"]["text"])
                self.assertEqual(second["transport"], [])
                self.assertEqual(second["toolCalls"], [])

                for turn in (first, second):
                    self.assertEqual(turn["llmCalls"], 0)
                    self.assertTrue(turn["observation"]["sideEffects"]["none"])

    def test_unknown_need_quantity_clarifies_without_inventing_or_committing(self) -> None:
        with LuaSemanticWorker(self.scenario("EN", {})) as worker:
            first = worker.input("Do you need anything?")
            second = worker.input("How many?")

        response = second["result"]["decision"]["response"]
        plan = response["plan"]
        self.assertEqual(
            response["templateID"], "semantic.question.needs.quantity.unknown"
        )
        self.assertEqual(plan["dialogueAct"], "ASK_CLARIFICATION")
        self.assertEqual(plan["uncertainty"], "ambiguous")
        self.assertEqual(plan["groundedFactRefs"], [])
        self.assertIn("exact amount", second["messages"][0]["payload"]["text"])
        self.assertNotIn("two", second["messages"][0]["payload"]["text"].lower())
        self.assertEqual(second["transport"], [])
        self.assertEqual(second["toolCalls"], [])
        self.assertTrue(second["observation"]["sideEffects"]["none"])
        self.assertEqual(
            second["contextAfter"]["dialogue"]["lastFollowUp"]["status"],
            "fulfilled",
        )
        self.assertEqual(first["transport"], [])
        self.assertEqual(first["toolCalls"], [])

    def test_standalone_how_many_remains_clarification_without_pending_context(self) -> None:
        with LuaSemanticWorker(self.scenario("EN", {})) as worker:
            turn = worker.input("How many?")

        ir = turn["result"]["ir"]
        self.assertEqual(ir["subject"], "QUANTITY")
        self.assertEqual(
            turn["result"]["decision"]["response"]["plan"]["dialogueAct"],
            "ASK_CLARIFICATION",
        )
        self.assertIsNone(turn["contextAfter"]["dialogue"].get("pendingFollowUp"))
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
