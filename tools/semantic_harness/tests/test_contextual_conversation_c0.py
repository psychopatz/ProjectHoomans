"""C0 characterization for the required contextual conversation on real Lua."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC0Tests(unittest.TestCase):
    def test_required_sequence_stops_before_needs_agenda_and_preserves_safety(self) -> None:
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
        self.assertEqual(
            [turn["result"]["decision"]["branch"] for turn in turns[2:]],
            ["ASK_CLARIFICATION"] * 5,
        )
        self.assertEqual(
            turns[2]["result"]["decision"]["response"]["templateID"],
            "semantic.ask_clarification",
        )
        self.assertTrue(turns[2]["result"]["ir"]["diagnostics"]["noMatch"])
        self.assertEqual(turns[2]["transport"], [])
        self.assertEqual(turns[2]["toolCalls"], [])
        self.assertEqual(turns[2]["llmCalls"], 0)
        self.assertIsNone(turns[4]["result"].get("actionResult"))
        self.assertEqual(
            turns[5]["result"]["decision"]["response"]["templateID"],
            "semantic.ask_clarification",
        )
        self.assertTrue(turns[5]["result"]["ir"]["diagnostics"]["noMatch"])


if __name__ == "__main__":
    unittest.main()
