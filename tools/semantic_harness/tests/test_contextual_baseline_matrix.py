"""Manually reviewed Phase 0B baseline matrix on the real Lua worker.

This is characterization only. It records the current deterministic contracts
and transport traces without adding a reaction selector or changing gameplay.
"""

from __future__ import annotations

import unittest

from tools.semantic_harness.runner import HarnessCase, run_case
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualBaselineMatrixTests(unittest.TestCase):
    def assert_one_turn_contract(self, turn: dict, *, intent: str,
                                 subject: str | None, pattern: str,
                                 response_prefix: str) -> dict:
        self.assertTrue(turn["accepted"], turn.get("reason"))
        result = turn["result"]
        ir = result["ir"]
        decision = result["decision"]
        response = decision["response"]
        self.assertEqual(ir["intent"], intent)
        self.assertEqual(ir.get("subject"), subject)
        self.assertEqual(ir["provenance"]["pattern"], pattern)
        self.assertEqual(decision["route"], "deterministic")
        self.assertTrue(response["templateID"].startswith(response_prefix), response)
        self.assertEqual(turn["contextBefore"]["state"], None)
        self.assertIsInstance(turn["contextAfter"]["state"], dict)
        self.assertIsInstance(turn["routedSituation"], dict)
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertEqual(len(turn["messages"]), 1)
        return turn

    def test_reviewed_one_turn_matrix_uses_production_context(self) -> None:
        cases = (
            (
                "greeting_default", {}, "hello there", "GREET", None,
                "pnc.social.greet", "semantic.greet.withdrawn",
            ),
            (
                "wellbeing_injured", {
                    "npc": {
                        "healthState": "injured",
                        "activeBehavior": "treatment",
                        "needs": {},
                        "conditionStats": {},
                    },
                }, "Are you okay?", "QUESTION", "WELLBEING",
                "pnc.question.wellbeing_okay",
                "semantic.question.wellbeing.injured",
            ),
            (
                "activity_fishing", {
                    "npc": {
                        "activeBehavior": "fishing",
                        "needs": {},
                        "conditionStats": {},
                    },
                }, "What are you doing?", "QUESTION", "ACTIVITY",
                "pnc.question.activity", "semantic.question.activity.fishing",
            ),
            (
                "time_default", {}, "What time is it?", "QUESTION", "TIME",
                "pnc.question.time", "semantic.question.time",
            ),
        )
        for label, override, text, intent, subject, pattern, response in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(merge(DEFAULT_SCENARIO, override)) as worker:
                    turn = worker.input(text)
                self.assert_one_turn_contract(
                    turn,
                    intent=intent,
                    subject=subject,
                    pattern=pattern,
                    response_prefix=response,
                )
                situation = turn["routedSituation"]["npc"]
                if label == "wellbeing_injured":
                    self.assertEqual(situation["healthState"], "injured")
                    self.assertEqual(situation["activity"]["id"], "treatment")
                elif label == "activity_fishing":
                    self.assertEqual(situation["activity"]["id"], "fishing")

    def test_identity_matrix_records_authorized_transport_and_effect(self) -> None:
        result = run_case(HarnessCase.from_mapping({
            "id": "contextual_identity_exchange",
            "scenario": {},
            "inputs": ["who are you", "im psycho"],
        }))
        self.assertEqual(result.conflicts, [])
        self.assertEqual(len(result.turns), 2)
        first, second = result.turns
        self.assert_one_turn_contract(
            first,
            intent="QUESTION",
            subject="IDENTITY",
            pattern="pnc.question.identity",
            response_prefix="semantic.question.identity",
        )
        self.assertTrue(second["accepted"], second.get("reason"))
        second_result = second["result"]
        self.assertEqual(second_result["sequence"], 2)
        self.assertEqual(second_result["ir"]["intent"], "INFORM")
        self.assertEqual(second_result["ir"]["subject"], "IDENTITY")
        self.assertEqual(
            second_result["ir"]["provenance"]["pattern"],
            "pnc.identity.self_name_im_plain",
        )
        self.assertEqual(second_result["decision"]["route"], "deterministic")
        self.assertTrue(
            second_result["decision"]["response"]["templateID"].startswith(
                "semantic.identity.exchange"
            )
        )
        self.assertEqual(second["contextBefore"]["state"]["sequence"], 1)
        self.assertEqual(second["contextAfter"]["state"]["sequence"], 2)
        self.assertEqual(second["llmCalls"], 0)
        self.assertTrue(any(
            event.get("command") == "SemanticIdentityRequest"
            and event.get("direction") == "client_to_server"
            for event in second["transport"]
        ))
        self.assertTrue(any(
            event.get("command") == "SemanticIdentityResult"
            and event.get("direction") == "server_to_client"
            for event in second["transport"]
        ))
        self.assertEqual(
            {call["name"] for call in second["toolCalls"]},
            {"SemanticIdentityRequest", "AdjustRelationship"},
        )

    def test_wellbeing_follow_up_reuses_bounded_answer_context(self) -> None:
        result = run_case(HarnessCase.from_mapping({
            "id": "contextual_wellbeing_follow_up",
            "scenario": {
                "npc": {
                    "healthState": "injured",
                    "activeBehavior": "treatment",
                    "needs": {},
                    "conditionStats": {},
                },
            },
            "inputs": ["Are you okay?", "What's wrong?"],
        }))
        self.assertEqual(result.conflicts, [])
        first, second = result.turns
        self.assert_one_turn_contract(
            first,
            intent="QUESTION",
            subject="WELLBEING",
            pattern="pnc.question.wellbeing_okay",
            response_prefix="semantic.question.wellbeing.injured",
        )
        self.assertTrue(second["accepted"], second.get("reason"))
        second_result = second["result"]
        self.assertEqual(second_result["ir"]["intent"], "QUESTION")
        self.assertEqual(second_result["ir"]["subject"], "WELLBEING")
        self.assertEqual(
            second_result["ir"]["provenance"]["pattern"],
            "pnc.question.wellbeing_follow_up_whats_wrong",
        )
        self.assertEqual(
            second_result["ir"]["extensions"]["dialogueFollowUp"],
            "WELLBEING",
        )
        self.assertEqual(second_result["decision"]["branch"], "QUESTION_RECEIVED")
        self.assertTrue(
            second_result["decision"]["response"]["templateID"].startswith(
                "semantic.question.wellbeing.follow_up.injured"
            )
        )
        self.assertEqual(second["contextBefore"]["state"]["sequence"], 1)
        self.assertEqual(second["contextAfter"]["state"]["sequence"], 2)
        before_dialogue = second["contextBefore"]["dialogue"]
        after_dialogue = second["contextAfter"]["dialogue"]
        self.assertEqual(before_dialogue["sequence"], 2)
        self.assertEqual(before_dialogue["currentTopic"], "wellbeing")
        self.assertEqual(before_dialogue["lastSpeaker"], "npc")
        self.assertEqual(after_dialogue["sequence"], 4)
        self.assertEqual(after_dialogue["currentTopic"], "wellbeing")
        self.assertLessEqual(len(after_dialogue["recentTurns"]), 12)
        self.assertEqual(second["llmCalls"], 0)
        self.assertEqual(second["transport"], [])
        self.assertEqual(second["toolCalls"], [])

    def test_wellbeing_follow_up_preview_is_idempotent(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {
            "npc": {
                "healthState": "injured",
                "activeBehavior": "treatment",
                "needs": {},
                "conditionStats": {},
            },
        })
        with LuaSemanticWorker(scenario) as worker:
            first = worker.input("Are you okay?")
            before = worker.snapshot()
            preview_one = worker.preview("What is wrong?")
            preview_two = worker.preview("What is wrong?")
            after = worker.snapshot()
        self.assertTrue(first["accepted"], first.get("reason"))
        self.assertTrue(preview_one["accepted"], preview_one.get("reason"))
        self.assertTrue(preview_two["accepted"], preview_two.get("reason"))
        self.assertEqual(
            preview_one["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.wellbeing_follow_up_what_is_wrong",
        )
        self.assertEqual(
            preview_one["result"]["decision"]["response"]["templateID"],
            "semantic.question.wellbeing.follow_up.injured",
        )
        self.assertEqual(preview_one["result"], preview_two["result"])
        self.assertEqual(preview_one["contextBefore"], preview_one["contextAfter"])
        self.assertEqual(preview_two["contextBefore"], preview_two["contextAfter"])
        self.assertEqual(
            {key: value for key, value in before.items() if key != "id"},
            {key: value for key, value in after.items() if key != "id"},
        )
        self.assertEqual(preview_one["messages"], [])
        self.assertEqual(preview_one["transport"], [])
        self.assertEqual(preview_one["toolCalls"], [])
        self.assertEqual(preview_one["llmCalls"], 0)


if __name__ == "__main__":
    unittest.main()
