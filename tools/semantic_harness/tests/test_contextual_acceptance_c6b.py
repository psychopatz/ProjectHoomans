"""C6-B mandatory contextual conversation and negative-language matrix."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def conversation_scenario(language: str) -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "npc": {
                "healthState": "unknown",
                "needs": {"thirst": 0.9},
                "conditionStats": {},
            },
            "world": {"weather": "rain"},
            "runtime": {"language": language},
        },
    )


class ContextualAcceptanceC6BTests(unittest.TestCase):
    def test_mandatory_conversation_is_grounded_and_resumes_in_en_and_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(conversation_scenario(language)) as worker:
                    turns = [
                        worker.input("Are you okay?"),
                        worker.input("What happened?"),
                        worker.input("Do you need anything?"),
                        worker.input("How many?"),
                        worker.input("I'll get some"),
                        worker.input("Can we talk about the weather"),
                        worker.input("Okay"),
                    ]

                for turn in turns:
                    self.assertTrue(turn["accepted"], turn.get("reason"))
                    self.assertTrue(turn["messages"][0]["payload"]["text"])
                    self.assertEqual(turn["translation"]["language"], language)
                    self.assertEqual(turn["llmCalls"], 0)
                    self.assertEqual(turn["transport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertTrue(turn["observation"]["sideEffects"]["none"])

                wellbeing, happened, needs, quantity, promise, weather, resumed = turns
                self.assertEqual(wellbeing["result"]["ir"]["subject"], "WELLBEING")
                self.assertEqual(happened["result"]["ir"]["subject"], "WELLBEING")
                self.assertEqual(
                    happened["result"]["decision"]["response"]["plan"]["groundedFactRefs"],
                    [],
                )
                self.assertEqual(needs["result"]["ir"]["subject"], "NEEDS")
                self.assertEqual(
                    needs["result"]["decision"]["response"]["plan"]["groundedFactRefs"],
                    ["npc.needs.thirst"],
                )
                self.assertEqual(quantity["result"]["ir"]["subject"], "QUANTITY")
                self.assertEqual(
                    quantity["result"]["decision"]["response"]["plan"]["dialogueAct"],
                    "NEEDS_QUANTITY",
                )
                self.assertEqual(promise["result"]["ir"]["intent"], "PROMISE")
                self.assertIsNone(promise["result"]["ir"].get("action"))
                self.assertEqual(
                    promise["result"]["decision"]["response"]["plan"]["uncertainty"],
                    "pending",
                )
                self.assertEqual(
                    promise["contextAfter"]["dialogue"]["pendingFollowUp"]["status"],
                    "open",
                )
                self.assertEqual(weather["result"]["ir"]["subject"], "WEATHER")
                self.assertEqual(
                    weather["result"]["ir"]["provenance"]["pattern"],
                    "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                )
                self.assertEqual(
                    weather["result"]["decision"]["response"]["plan"]["groundedFactRefs"],
                    ["world.weather.raining"],
                )
                self.assertEqual(weather["observation"]["flow"]["transition"], "interrupt_start")
                self.assertEqual(weather["contextAfter"]["dialogue"]["currentTopic"], "weather")
                self.assertEqual(resumed["result"]["ir"]["intent"], "ACCEPT")
                self.assertEqual(resumed["observation"]["flow"]["transition"], "resume_match")
                self.assertEqual(resumed["contextAfter"]["dialogue"]["currentTopic"], "needs")
                self.assertEqual(
                    resumed["contextAfter"]["dialogue"]["previousTopic"],
                    "weather",
                )
                self.assertEqual(
                    resumed["contextAfter"]["dialogue"]["pendingFollowUp"]["status"],
                    "open",
                )

    def test_negative_dataset_examples_abstain_without_false_effects(self) -> None:
        with LuaSemanticWorker(conversation_scenario("EN")) as worker:
            turns = [
                worker.input("I won't pick some up"),
                worker.input("Can we talk about weather"),
                worker.input("Which items do you mean"),
            ]

        for turn in turns:
            self.assertTrue(turn["accepted"], turn.get("reason"))
            self.assertIsNone(turn["result"]["ir"].get("intent"))
            self.assertIsNone(turn["result"]["ir"].get("action"))
            self.assertTrue(turn["messages"][0]["payload"]["text"])
            self.assertEqual(turn["transport"], [])
            self.assertEqual(turn["toolCalls"], [])
            self.assertEqual(turn["llmCalls"], 0)
            self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
