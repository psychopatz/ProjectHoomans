"""C3-C confirmation-safe needs promise on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC3CTests(unittest.TestCase):
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

    def test_get_some_stays_an_unconfirmed_proposal_en_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(
                    self.scenario(language, {"hunger": 0.9})
                ) as worker:
                    worker.input("Do you need anything?")
                    worker.input("How many?")
                    turn = worker.input("I'll get some")

                result = turn["result"]
                ir = result["ir"]
                response = result["decision"]["response"]
                plan = response["plan"]
                pending = turn["contextAfter"]["dialogue"][
                    "pendingFollowUp"
                ]
                last = turn["contextAfter"]["dialogue"]["lastFollowUp"]

                self.assertTrue(turn["accepted"], turn.get("reason"))
                self.assertEqual(ir["intent"], "PROMISE")
                self.assertEqual(ir["speechAct"], "PROMISE")
                self.assertEqual(ir["subject"], "NEEDS")
                self.assertIsNone(ir.get("action"))
                self.assertEqual(
                    ir["provenance"]["pattern"],
                    "pnc.promise.needs_get_some",
                )
                self.assertEqual(
                    response["templateID"],
                    "semantic.question.needs.proposal.hunger",
                )
                self.assertEqual(plan["dialogueAct"], "PROMISE_ACKNOWLEDGEMENT")
                self.assertEqual(plan["topic"], "NEEDS")
                self.assertEqual(plan["uncertainty"], "pending")
                self.assertEqual(plan["groundedFactRefs"], ["npc.needs.hunger"])
                self.assertEqual(
                    turn["observation"]["flow"]["transition"], "match"
                )
                self.assertEqual(
                    turn["observation"]["flow"]["responsePoolID"],
                    "semantic.question.needs.proposal",
                )
                self.assertEqual(pending["kind"], "PROPOSAL")
                self.assertEqual(pending["status"], "open")
                self.assertEqual(pending["requiredSlots"], ["confirmation"])
                self.assertEqual(pending["sourceFactRefs"], ["npc.needs"])
                self.assertEqual(last["status"], "fulfilled")
                self.assertEqual(last["nodeID"], "quantity_answer")
                self.assertEqual(last["requiredSlots"], ["offer"])
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(turn["llmCalls"], 0)
                self.assertTrue(turn["observation"]["sideEffects"]["none"])
                self.assertEqual(turn["translation"]["language"], language)
                self.assertTrue(turn["messages"][0]["payload"]["text"])


if __name__ == "__main__":
    unittest.main()
