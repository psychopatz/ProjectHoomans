"""C1-A pending follow-up and topic interruption on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualConversationC1Tests(unittest.TestCase):
    @staticmethod
    def message_text(turn: dict) -> str:
        messages = turn.get("messages", [])
        if not messages:
            return ""
        payload = messages[-1].get("payload", {})
        return payload.get("text") or payload.get("fallback") or ""

    def test_screenshot_sequence_supports_causal_and_reciprocal_compound_turns(
        self,
    ) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            residence = worker.input("where do you live")
            cause = worker.input("why is it so?")
            greeting = worker.input("hello")
            compound = worker.input("im fine, how about you")

        self.assertEqual(residence["result"]["ir"]["subject"], "NPC_RESIDENCE")
        self.assertEqual(
            cause["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.context_reference.why_is_it_so",
        )
        self.assertEqual(cause["result"]["ir"]["subject"], "CONTEXT_REFERENCE")
        self.assertIn("why", self.message_text(cause).lower())
        self.assertNotIn("not sure what you mean", self.message_text(cause).lower())

        self.assertEqual(len(greeting["messages"]), 2)
        compound_result = compound["result"]
        self.assertEqual(
            compound_result["compound"]["parts"][0]["pattern"],
            "pnc.state.self_wellbeing_im_plain_fine",
        )
        self.assertEqual(
            compound_result["compound"]["parts"][1]["pattern"],
            "pnc.question.wellbeing_reciprocal_how_about_you",
        )
        self.assertTrue(compound_result["compound"]["parts"][0]["accepted"])
        self.assertEqual(
            compound_result["ir"]["subject"], "WELLBEING_RECIPROCAL"
        )
        self.assertEqual(len(compound["messages"]), 1)
        self.assertTrue(self.message_text(compound))
        self.assertNotIn(
            "not sure what you mean", self.message_text(compound).lower()
        )
        self.assertIsNone(
            compound["contextAfter"]["dialogue"].get("pendingFollowUp")
        )
        for turn in (residence, cause, greeting, compound):
            self.assertEqual(turn["llmCalls"], 0)
            self.assertEqual(turn["transport"], [])
            self.assertEqual(turn["toolCalls"], [])

    def test_compound_reciprocal_turn_localizes_in_tagalog(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {"runtime": {"language": "TL"}})
        with LuaSemanticWorker(scenario) as worker:
            turn = worker.input("im fine, how about you")

        self.assertEqual(turn["translation"]["language"], "TL")
        self.assertEqual(
            turn["result"]["compound"]["parts"][1]["pattern"],
            "pnc.question.wellbeing_reciprocal_how_about_you",
        )
        self.assertNotEqual(
            turn["messages"][0]["payload"]["text"],
            turn["messages"][0]["payload"]["fallback"],
        )
        self.assertEqual(turn["observation"]["translation"]["fallbackCount"], 0)

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
