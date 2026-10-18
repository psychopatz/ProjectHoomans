"""C0 characterization for the required contextual conversation on real Lua."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC0Tests(unittest.TestCase):
    def test_required_sequence_advances_needs_quantity_and_preserves_safety(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {
            "npc": {
                "healthState": "injured",
                "activeBehavior": "treatment",
                "needs": {},
                "conditionStats": {},
            },
        })
        inputs = (
            "Are you okay?",
            "What happened?",
            "Do you need anything?",
            "How many?",
            "I'll get some",
            "What's the weather?",
            "How many?",
        )
        with LuaSemanticWorker(scenario) as worker:
            turns = [worker.input(text) for text in inputs]

        self.assertEqual(
            [turn["result"]["ir"].get("subject") for turn in turns[:2]],
            ["WELLBEING", "WELLBEING"],
        )
        self.assertEqual(turns[2]["result"]["ir"]["subject"], "NEEDS")
        self.assertEqual(
            turns[2]["result"]["decision"]["branch"], "QUESTION_RECEIVED"
        )
        self.assertEqual(
            turns[2]["result"]["decision"]["response"]["templateID"],
            "semantic.question.needs.offer.unknown",
        )
        self.assertEqual(
            turns[2]["contextAfter"]["dialogue"]["pendingFollowUp"][
                "requiredSlots"
            ],
            ["quantity"],
        )
        self.assertEqual(turns[3]["result"]["ir"]["subject"], "QUANTITY")
        self.assertEqual(
            turns[3]["result"]["decision"]["response"]["templateID"],
            "semantic.question.needs.quantity.unknown",
        )
        self.assertIsNone(
            turns[3]["contextAfter"]["dialogue"].get("pendingFollowUp")
        )
        self.assertEqual(
            turns[3]["contextAfter"]["dialogue"]["lastFollowUp"]["status"],
            "fulfilled",
        )
        self.assertEqual(
            turns[2]["transport"], []
        )
        self.assertEqual(turns[3]["transport"], [])
        self.assertEqual(turns[3]["toolCalls"], [])
        self.assertEqual(turns[3]["llmCalls"], 0)
        self.assertEqual(
            turns[4]["result"]["decision"]["response"]["templateID"],
            "semantic.ask_clarification",
        )
        self.assertTrue(turns[4]["result"]["ir"]["diagnostics"]["noMatch"])
        self.assertIsNone(turns[4]["result"].get("actionResult"))
        self.assertEqual(
            turns[5]["result"]["decision"]["response"]["templateID"],
            "semantic.ask_clarification",
        )
        self.assertTrue(turns[5]["result"]["ir"]["diagnostics"]["noMatch"])
        self.assertEqual(
            turns[6]["result"]["decision"]["response"]["templateID"],
            "semantic.question.needs.quantity.unknown",
        )
        self.assertIsNone(
            turns[6]["contextAfter"]["dialogue"].get("pendingFollowUp")
        )
        for turn in turns[4:]:
            self.assertEqual(turn["transport"], [])
            self.assertEqual(turn["toolCalls"], [])
            self.assertEqual(turn["llmCalls"], 0)


if __name__ == "__main__":
    unittest.main()
