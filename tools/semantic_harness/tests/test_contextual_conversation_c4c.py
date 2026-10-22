"""C4-C reviewed weather topic switch and existing-flow resumption on Lua."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualConversationC4CTests(unittest.TestCase):
    @staticmethod
    def scenario(language: str) -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "needs": {"hunger": 0.9},
                    "conditionStats": {},
                },
                "runtime": {"language": language},
                "world": {"weather": "rain"},
            },
        )

    def test_reviewed_weather_mapping_preserves_and_resumes_proposal_en_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(self.scenario(language)) as worker:
                    worker.input("Do you need anything?")
                    worker.input("How many?")
                    worker.input("I'll get some")
                    weather = worker.input("Can we talk about the weather")
                    resumed = worker.input("Okay")

                weather_ir = weather["result"]["ir"]
                weather_context = weather["contextAfter"]["dialogue"]
                weather_pending = weather_context["pendingFollowUp"]
                weather_flow = weather["observation"]["flow"]
                weather_response = weather["result"]["decision"]["response"]
                resumed_context = resumed["contextAfter"]["dialogue"]

                self.assertEqual(weather_ir["intent"], "QUESTION")
                self.assertEqual(weather_ir["subject"], "WEATHER")
                self.assertEqual(
                    weather_ir["provenance"]["pattern"],
                    "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                )
                self.assertEqual(
                    weather_ir["diagnostics"]["candidateSelection"]["selectedPattern"],
                    "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                )
                self.assertEqual(weather_flow["transition"], "interrupt_start")
                self.assertEqual(weather_context["currentTopic"], "weather")
                self.assertEqual(weather_context["previousTopic"], "needs")
                self.assertEqual(weather_pending["kind"], "PROPOSAL")
                self.assertEqual(weather_pending["status"], "open")
                self.assertEqual(
                    weather_response["templateID"],
                    "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                )
                self.assertEqual(
                    weather_response["plan"]["dialogueAct"],
                    "WEATHER_REPORT",
                )
                self.assertEqual(
                    weather_response["plan"]["groundedFactRefs"],
                    ["world.weather.raining"],
                )
                self.assertEqual(weather["translation"]["language"], language)
                self.assertTrue(weather["messages"][0]["payload"]["text"])

                self.assertEqual(resumed["result"]["ir"]["intent"], "ACCEPT")
                self.assertEqual(
                    resumed["observation"]["flow"]["transition"],
                    "resume_match",
                )
                self.assertEqual(resumed_context["currentTopic"], "needs")
                self.assertEqual(resumed_context["previousTopic"], "weather")
                self.assertEqual(resumed_context["pendingFollowUp"]["status"], "open")
                for turn in (weather, resumed):
                    self.assertEqual(turn["llmCalls"], 0)
                    self.assertEqual(turn["transport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertTrue(turn["observation"]["sideEffects"]["none"])

    def test_nearby_negative_abstains_without_dispatch(self) -> None:
        with LuaSemanticWorker(self.scenario("EN")) as worker:
            turn = worker.input("Can we talk about weather")

        self.assertIsNone(turn["result"]["ir"].get("intent"))
        self.assertIsNone(turn["result"]["ir"].get("action"))
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
