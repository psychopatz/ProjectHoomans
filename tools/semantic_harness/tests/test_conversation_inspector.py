"""Conversation State Inspector projection over the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.conversation_inspector import build_conversation_inspector
from tools.semantic_harness.rendering import conversation_first
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ConversationInspectorTests(unittest.TestCase):
    @staticmethod
    def scenario(language: str = "EN") -> dict:
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

    def test_projects_real_turn_context_plan_flow_response_and_trace(self) -> None:
        with LuaSemanticWorker(self.scenario()) as worker:
            worker.input("Do you need anything?")
            worker.input("How many?")
            worker.input("I'll get some")
            turn = worker.input("Can we talk about the weather")

        view = build_conversation_inspector(turn)

        self.assertEqual(view["source"], "real_lua_worker")
        self.assertEqual(view["context"]["currentTopic"], "weather")
        self.assertEqual(view["context"]["previousTopic"], "needs")
        self.assertEqual(view["context"]["pendingObligation"]["kind"], "PROPOSAL")
        self.assertEqual(view["context"]["pendingObligation"]["status"], "open")
        self.assertEqual(
            view["semantic"]["pattern"],
            "pnc.dataset.question.weather.can_we_talk_about_the_weather",
        )
        self.assertEqual(view["selectedFlow"]["transition"], "interrupt_start")
        self.assertEqual(
            view["dialoguePlan"]["dialogueAct"],
            "WEATHER_REPORT",
        )
        self.assertEqual(
            view["memoryProvenance"]["planFactRefs"],
            ["world.weather.raining"],
        )
        self.assertEqual(
            view["visibleResponse"]["translationKey"],
            "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
        )
        self.assertTrue(view["workerTrace"])
        self.assertTrue(view["effects"]["sideEffects"]["none"])

    def test_snapshot_uses_authoritative_context_and_bounds_trace(self) -> None:
        with LuaSemanticWorker(self.scenario()) as worker:
            for text in (
                "Do you need anything?",
                "How many?",
                "I'll get some",
                "Can we talk about the weather",
            ):
                worker.input(text)
            snapshot = worker.snapshot()

        view = build_conversation_inspector(snapshot)

        self.assertEqual(view["source"], "real_lua_worker")
        self.assertEqual(view["context"]["currentTopic"], "weather")
        self.assertEqual(view["context"]["pendingObligation"]["kind"], "PROPOSAL")
        self.assertLessEqual(len(view["workerTrace"]), 16)
        self.assertNotIn("transcript", view)
        self.assertIsNone(view["dialoguePlan"])

    def test_projects_social_policy_authority_result_and_final_text(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "runtime": {
                        "conversationLease": {"token": "authority-token"},
                    },
                },
                "conversation": {"token": "client-token"},
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            turn = worker.input("fuck you")

        view = build_conversation_inspector(turn)
        self.assertEqual(view["execution"]["route"], "deterministic")
        self.assertEqual(view["execution"]["branch"], "HOSTILE_REMARK_RECEIVED")
        self.assertEqual(view["execution"]["owner"], "policy")
        self.assertEqual(view["execution"]["status"], "rejected")
        self.assertEqual(view["execution"]["rejectionReason"], "invalid_lease")
        self.assertEqual(view["execution"]["authority"], "server")
        self.assertEqual(
            view["execution"]["finalText"],
            "I heard you, but I couldn't apply that social reaction.",
        )

    def test_conversation_first_projection_separates_understanding_and_authority(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {"npc": {"residence": {"label": "Riverside Camp"}}},
        )
        with LuaSemanticWorker(scenario) as worker:
            worker.input("where is your home")
            reference_turn = worker.input("what about it")
            command_turn = worker.input("wait here")

        reference_view = build_conversation_inspector(reference_turn)
        self.assertEqual(
            reference_view["understanding"]["classification"],
            "recognized_question",
        )
        self.assertEqual(
            reference_view["understanding"]["reference"]["resolvedReference"],
            "IT",
        )
        self.assertEqual(
            reference_view["understanding"]["reference"]["concept"],
            "NPC_RESIDENCE",
        )
        self.assertEqual(reference_view["facts"]["status"], "known")
        self.assertEqual(
            reference_view["dialoguePlanning"]["selectionSource"],
            "conversation_reference",
        )
        self.assertIn(
            "Riverside Camp",
            reference_view["finalResponse"]["text"],
        )
        self.assertFalse(reference_view["commandAuthority"]["isGameplayAction"])
        self.assertEqual(
            reference_view["commandAuthority"]["effects"]["transportCount"],
            0,
        )

        command_view = build_conversation_inspector(command_turn)
        self.assertTrue(command_view["commandAuthority"]["isGameplayAction"])
        self.assertEqual(command_view["commandAuthority"]["action"], "STAY")
        self.assertEqual(
            command_view["commandAuthority"]["capabilityID"],
            "pnc:companion.stay",
        )
        self.assertEqual(
            command_view["commandAuthority"]["effects"]["transportCount"],
            1,
        )

        rendered = conversation_first(reference_view)
        self.assertLess(
            rendered.index("UNDERSTANDING"), rendered.index("CONTEXT")
        )
        self.assertLess(
            rendered.index("FINAL NPC RESPONSE"),
            rendered.index("COMMAND AUTHORITY (SEPARATE)"),
        )


if __name__ == "__main__":
    unittest.main()
