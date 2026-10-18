"""C1-A pending follow-up and topic interruption on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualConversationC1Tests(unittest.TestCase):
    def test_pending_follow_up_survives_weather_and_resumes_wellbeing(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "activeBehavior": "treatment",
                    "needs": {},
                    "conditionStats": {},
                },
                "world": {"weather": "rain"},
            },
        )

        with LuaSemanticWorker(scenario) as worker:
            wellbeing = worker.input("Are you okay?")
            weather = worker.input("Is it raining?")
            resumed = worker.input("What happened?")

        first_context = wellbeing["contextAfter"]["dialogue"]
        self.assertEqual(first_context["pendingFollowUp"]["topic"], "wellbeing")
        self.assertEqual(first_context["pendingFollowUp"]["status"], "open")
        self.assertEqual(first_context["agenda"][0]["status"], "open")
        self.assertEqual(
            wellbeing["observation"]["response"]["templateID"],
            "semantic.question.wellbeing.injured",
        )

        weather_ir = weather["result"]["ir"]
        weather_context = weather["contextAfter"]["dialogue"]
        self.assertEqual(weather_ir["subject"], "WEATHER")
        self.assertEqual(
            weather_ir["diagnostics"]["contextualFollowUp"]["status"],
            "interrupted",
        )
        self.assertEqual(weather_context["currentTopic"], "weather")
        self.assertEqual(weather_context["previousTopic"], "wellbeing")
        self.assertEqual(
            weather_context["pendingFollowUp"]["topic"], "wellbeing"
        )
        self.assertEqual(
            weather["observation"]["flow"]["transition"], "interrupt_start"
        )
        self.assertEqual(
            weather["observation"]["flow"]["activeAfter"][0]["suspended"][0][
                "flowId"
            ],
            "wellbeing",
        )
        self.assertEqual(
            weather["observation"]["response"]["templateID"],
            "semantic.flow.weather.raining.default",
        )

        resumed_ir = resumed["result"]["ir"]
        resumed_context = resumed["contextAfter"]["dialogue"]
        self.assertEqual(
            resumed_ir["diagnostics"]["contextualFollowUp"]["status"],
            "matched",
        )
        self.assertEqual(
            resumed_ir["provenance"]["pattern"],
            "pnc.recovery.contextual_question_wellbeing",
        )
        self.assertEqual(
            resumed["observation"]["flow"]["transition"], "resume_match"
        )
        self.assertEqual(resumed_context["currentTopic"], "wellbeing")
        self.assertEqual(resumed_context["previousTopic"], "weather")
        self.assertIsNone(resumed_context.get("pendingFollowUp"))
        self.assertEqual(resumed_context["lastFollowUp"]["status"], "fulfilled")
        self.assertEqual(resumed_context["agenda"][0]["status"], "fulfilled")
        self.assertEqual(
            resumed["observation"]["response"]["templateID"],
            "semantic.question.wellbeing.injured",
        )

        for turn in (wellbeing, weather, resumed):
            self.assertEqual(turn["llmCalls"], 0)
            self.assertEqual(turn["transport"], [])
            self.assertEqual(turn["toolCalls"], [])
            self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
