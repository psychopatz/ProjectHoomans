"""C3-A grounded response-plan composition on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC3Tests(unittest.TestCase):
    @staticmethod
    def scenario(language: str, social_style: str) -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "personality": {"socialStyle": social_style},
                    "needs": {},
                    "conditionStats": {},
                },
                "runtime": {"language": language},
            },
        )

    def test_grounded_wellbeing_plan_varies_tone_and_translates(self) -> None:
        for language, expected_tone in (("EN", "warm"), ("TL", "warm")):
            with self.subTest(language=language):
                with LuaSemanticWorker(
                    self.scenario(language, "friendly")
                ) as worker:
                    turn = worker.input("Are you okay?")

                response = turn["result"]["decision"]["response"]
                plan = response["plan"]
                payload = turn["messages"][0]["payload"]
                observation = turn["observation"]["response"]

                self.assertTrue(turn["accepted"], turn.get("reason"))
                self.assertEqual(
                    response["templateID"],
                    "semantic.question.wellbeing.grounded.friendly",
                )
                self.assertEqual(plan["dialogueAct"], "WELLBEING_REPORT")
                self.assertEqual(
                    plan["sourcePoolID"],
                    "semantic.question.wellbeing.grounded",
                )
                self.assertEqual(plan["topic"], "WELLBEING")
                self.assertEqual(plan["groundedFactRefs"], ["npc.healthState"])
                self.assertEqual(plan["uncertainty"], "known")
                self.assertEqual(plan["tone"], expected_tone)
                self.assertEqual(plan["personalityStyle"], "friendly")
                self.assertEqual(len(plan["turns"]), 1)
                self.assertEqual(len(plan["turns"][0]["segments"]), 2)
                self.assertEqual(payload["plan"], plan)
                self.assertEqual(observation["dialogueAct"], "WELLBEING_REPORT")
                self.assertEqual(
                    observation["groundedFactRefs"], ["npc.healthState"]
                )
                self.assertEqual(observation["personalityStyle"], "friendly")
                self.assertEqual(turn["translation"]["language"], language)
                self.assertEqual(len(observation["queued"]), 1)
                self.assertEqual(len(observation["queued"][0]["translationKeys"]), 2)
                self.assertEqual(turn["llmCalls"], 0)
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertTrue(observation["queued"][0]["text"])
                if language == "TL":
                    self.assertNotEqual(
                        observation["queued"][0]["text"],
                        observation["queued"][0]["fallback"],
                    )

    def test_same_grounding_supports_withdrawn_tone_without_side_effects(self) -> None:
        with LuaSemanticWorker(self.scenario("EN", "withdrawn")) as worker:
            turn = worker.input("Are you okay?")

        response = turn["result"]["decision"]["response"]
        plan = response["plan"]
        self.assertEqual(
            response["templateID"],
            "semantic.question.wellbeing.grounded.withdrawn",
        )
        self.assertEqual(plan["groundedFactRefs"], ["npc.healthState"])
        self.assertEqual(plan["uncertainty"], "known")
        self.assertEqual(plan["tone"], "guarded")
        self.assertEqual(plan["personalityStyle"], "withdrawn")
        self.assertNotEqual(
            turn["messages"][0]["payload"]["text"],
            "I took a bad hit, but I'm steady enough to keep moving. Thanks for checking in.",
        )
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertTrue(turn["observation"]["sideEffects"]["none"])

    def test_unknown_health_does_not_select_grounded_plan(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "unknown",
                    "personality": {"socialStyle": "friendly"},
                    "needs": {},
                    "conditionStats": {},
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            turn = worker.input("Are you okay?")

        response = turn["result"]["decision"]["response"]
        self.assertEqual(
            response["templateID"], "semantic.question.wellbeing.unknown"
        )
        self.assertEqual(response["plan"]["groundedFactRefs"], [])
        self.assertNotIn("hurt", turn["messages"][0]["payload"]["fallback"])
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
