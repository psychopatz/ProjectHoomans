"""Phase 4 bounded paraphrase probes on the real Lua semantic worker.

This slice adds one explicitly reviewed wellbeing paraphrase and characterizes
nearby command-shaped hold-outs so the dataset change cannot broaden authority
or route ambiguous language into an action.
"""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class SemanticParaphraseTests(unittest.TestCase):
    def test_reviewed_wellbeing_paraphrase_preserves_offline_contract(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            turn = worker.input("how are you doing")

        self.assertTrue(turn["accepted"], turn.get("reason"))
        result = turn["result"]
        ir = result["ir"]
        decision = result["decision"]
        self.assertEqual(ir["intent"], "QUESTION")
        self.assertEqual(ir["speechAct"], "QUESTION")
        self.assertEqual(ir["subject"], "WELLBEING")
        self.assertEqual(
            ir["provenance"]["pattern"],
            "pnc.dataset.question.wellbeing.how_are_you_doing",
        )
        self.assertEqual(decision["branch"], "QUESTION_RECEIVED")
        self.assertEqual(decision["route"], "deterministic")
        self.assertTrue(
            decision["response"]["templateID"].startswith(
                "semantic.question.wellbeing."
            )
        )
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertIsNone(result.get("actionResult"))
        self.assertEqual(turn["relationshipBefore"], turn["relationshipAfter"])

    def test_existing_wellbeing_paraphrase_and_command_holdouts_remain_bounded(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            existing = worker.input("how are you holding up")

        self.assertTrue(existing["accepted"], existing.get("reason"))
        self.assertEqual(existing["result"]["ir"]["intent"], "QUESTION")
        self.assertEqual(existing["result"]["ir"]["subject"], "WELLBEING")
        self.assertEqual(
            existing["result"]["decision"]["branch"],
            "QUESTION_RECEIVED",
        )
        self.assertEqual(existing["transport"], [])
        self.assertEqual(existing["toolCalls"], [])
        self.assertEqual(existing["llmCalls"], 0)

        for text in ("walk with me", "followed the trail", "we are following them"):
            with self.subTest(text=text):
                with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                    turn = worker.input(text)
                self.assertTrue(turn["accepted"], turn.get("reason"))
                result = turn["result"]
                self.assertEqual(
                    result["decision"]["branch"],
                    "ASK_CLARIFICATION",
                )
                self.assertIsNone(result.get("actionResult"))
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(turn["llmCalls"], 0)
                self.assertEqual(
                    turn["relationshipBefore"], turn["relationshipAfter"]
                )

    def test_live_unpunctuated_wellbeing_follow_up_is_bounded(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            first = worker.input("Are you okay?")
            second = worker.input("whats wrong")

        self.assertTrue(first["accepted"], first.get("reason"))
        self.assertTrue(second["accepted"], second.get("reason"))
        self.assertEqual(
            second["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.wellbeing_follow_up_whats_plain",
        )
        self.assertEqual(
            second["result"]["decision"]["branch"],
            "QUESTION_RECEIVED",
        )
        self.assertEqual(second["llmCalls"], 0)
        self.assertEqual(second["transport"], [])
        self.assertEqual(second["toolCalls"], [])

    def test_contextual_fuzzy_question_recovers_paraphrase_and_typo(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {
            "npc": {
                "healthState": "injured",
                "activeBehavior": "treatment",
                "needs": {},
                "conditionStats": {},
            },
        })
        for text in ("what happened", "what happened?", "wat happend"):
            with self.subTest(text=text):
                with LuaSemanticWorker(scenario) as worker:
                    first = worker.input("Are you okay?")
                    second = worker.input(text)

                self.assertTrue(first["accepted"], first.get("reason"))
                self.assertTrue(second["accepted"], second.get("reason"))
                ir = second["result"]["ir"]
                decision = second["result"]["decision"]
                self.assertEqual(ir["intent"], "QUESTION")
                self.assertEqual(ir["subject"], "WELLBEING")
                self.assertEqual(
                    ir["provenance"]["pattern"],
                    "pnc.recovery.contextual_question_wellbeing",
                )
                self.assertTrue(ir["diagnostics"]["recoveredMatch"])
                self.assertEqual(decision["branch"], "QUESTION_RECEIVED")
                self.assertEqual(decision["route"], "deterministic")
                self.assertEqual(
                    decision["response"]["templateID"],
                    "semantic.question.wellbeing.follow_up.injured",
                )
                self.assertEqual(second["llmCalls"], 0)
                self.assertEqual(second["transport"], [])
                self.assertEqual(second["toolCalls"], [])

    def test_contextual_fuzzy_question_requires_conversation_topic(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            turn = worker.input("what happened")

        self.assertTrue(turn["accepted"], turn.get("reason"))
        result = turn["result"]
        self.assertEqual(result["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertTrue(result["ir"]["diagnostics"]["noMatch"])
        self.assertIsNone(result.get("actionResult"))
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
