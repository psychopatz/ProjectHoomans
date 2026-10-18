"""C3-D weather interruption and needs-proposal resumption on real Lua."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC3DTests(unittest.TestCase):
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

    def test_weather_interrupts_and_resumes_open_needs_proposal_en_tl(self):
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(self.scenario(language)) as worker:
                    worker.input("Do you need anything?")
                    worker.input("How many?")
                    worker.input("I'll get some")
                    weather = worker.input("What's the weather?")
                    resumed = worker.input("Okay")

                weather_ir = weather["result"]["ir"]
                weather_context = weather["contextAfter"]["dialogue"]
                weather_pending = weather_context["pendingFollowUp"]
                weather_flow = weather["observation"]["flow"]
                resumed_ir = resumed["result"]["ir"]
                resumed_context = resumed["contextAfter"]["dialogue"]
                resumed_flow = resumed["observation"]["flow"]
                resumed_pending = resumed_context["pendingFollowUp"]

                self.assertEqual(weather_ir["subject"], "WEATHER")
                self.assertEqual(
                    weather_ir["provenance"]["pattern"],
                    "pnc.question.weather",
                )
                self.assertEqual(
                    weather_ir["diagnostics"]["contextualFollowUp"][
                        "status"
                    ],
                    "interrupted",
                )
                self.assertEqual(weather_flow["transition"], "interrupt_start")
                self.assertEqual(
                    weather_flow["activeAfter"][0]["suspended"][0]["flowId"],
                    "needs",
                )
                self.assertEqual(weather_context["currentTopic"], "weather")
                self.assertEqual(weather_context["previousTopic"], "needs")
                self.assertEqual(weather_pending["kind"], "PROPOSAL")
                self.assertEqual(weather_pending["topic"], "needs")
                self.assertEqual(
                    weather["observation"]["response"]["templateID"],
                    "semantic.flow.weather.raining.default",
                )

                self.assertEqual(resumed_ir["intent"], "ACCEPT")
                self.assertEqual(
                    resumed_ir["diagnostics"]["contextualFollowUp"][
                        "status"
                    ],
                    "matched",
                )
                self.assertEqual(
                    resumed_ir["diagnostics"]["contextualFollowUp"][
                        "inputTopic"
                    ],
                    "NEEDS",
                )
                self.assertEqual(resumed_flow["transition"], "resume_match")
                self.assertEqual(resumed_context["currentTopic"], "needs")
                self.assertEqual(resumed_context["previousTopic"], "weather")
                self.assertEqual(resumed_pending["kind"], "PROPOSAL")
                self.assertEqual(resumed_pending["status"], "open")
                self.assertEqual(
                    resumed["observation"]["response"]["templateID"],
                    "semantic.question.needs.proposal.hunger",
                )
                self.assertEqual(resumed["translation"]["language"], language)
                self.assertTrue(resumed["messages"][0]["payload"]["text"])

                for turn in (weather, resumed):
                    self.assertEqual(turn["llmCalls"], 0)
                    self.assertEqual(turn["transport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
