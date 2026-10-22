"""C7D discourse continuity probes on the real Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ConversationalCompetenceC7DTests(unittest.TestCase):
    @staticmethod
    def message_text(turn: dict) -> str:
        payload = turn["messages"][-1]["payload"]
        if isinstance(payload, dict):
            return str(payload.get("text") or payload.get("fallback") or "")
        return str(payload or "")

    @staticmethod
    def assert_no_effects(turn: dict) -> None:
        assert turn["accepted"], turn.get("reason")
        assert turn["result"]["decision"]["route"] == "deterministic"
        assert turn["result"].get("actionResult") is None
        assert turn["transport"] == []
        assert turn["toolCalls"] == []
        assert turn["llmCalls"] == 0

    def test_pronoun_followups_requery_grounded_topics(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        scenario["npc"]["knowledge"] = {
            "topics": {
                "radio tower": {
                    "known": True,
                    "answer": "It is north of here.",
                }
            }
        }

        with LuaSemanticWorker(scenario) as worker:
            residence = worker.input("where is your home")
            residence_follow_up = worker.input("what about it")
            safety = worker.input("is it safe there")
            residence_that = worker.input("what about that")
            knowledge = worker.input("do you know about the radio tower")
            description = worker.input("what is it like there")
            knowledge_follow_up = worker.input("what about it")

        self.assertEqual(
            residence_follow_up["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.context_reference.what_about_it",
        )
        target = residence_follow_up["result"]["ir"]["target"]
        self.assertEqual(target["resolvedReference"], "IT")
        self.assertEqual(target["concept"], "NPC_RESIDENCE")
        fact = residence_follow_up["result"]["ir"]["extensions"]["facts"][
            "CONTEXT_REFERENCE"
        ]
        self.assertEqual(fact["subject"], "NPC_RESIDENCE")
        self.assertEqual(fact["status"], "known")
        self.assertIn("Riverside Camp", self.message_text(residence_follow_up))
        self.assertEqual(
            residence_follow_up["result"]["decision"]["response"][
                "selectionSource"
            ],
            "conversation_reference",
        )
        self.assertEqual(
            residence_follow_up["trace"][0]["data"]["classification"],
            "recognized_question",
        )
        self.assert_no_effects(residence)
        self.assert_no_effects(residence_follow_up)

        safety_fact = safety["result"]["ir"]["diagnostics"]
        self.assertEqual(safety_fact["factStatus"], "unknown")
        self.assertIn("reliable information", self.message_text(safety).lower())
        self.assertEqual(
            safety["trace"][0]["data"]["classification"],
            "recognized_question_unknown_fact",
        )
        self.assert_no_effects(safety)

        residence_that_fact = residence_that["result"]["ir"]["extensions"][
            "facts"
        ]["CONTEXT_REFERENCE"]
        self.assertEqual(residence_that_fact["subject"], "NPC_RESIDENCE")
        self.assertEqual(residence_that_fact["status"], "known")
        self.assertIn("Riverside Camp", self.message_text(residence_that))
        self.assert_no_effects(residence_that)

        self.assertEqual(
            knowledge["result"]["ir"]["diagnostics"]["factStatus"], "known"
        )
        self.assertIn("radio tower", self.message_text(knowledge).lower())
        self.assertEqual(
            description["result"]["ir"]["target"]["concept"],
            "NPC_KNOWLEDGE",
        )
        self.assertEqual(
            description["result"]["ir"]["diagnostics"]["factStatus"], "known"
        )
        self.assertIn("north of here", self.message_text(description).lower())
        self.assertIn("north of here", self.message_text(knowledge_follow_up).lower())
        self.assertEqual(
            knowledge_follow_up["result"]["ir"]["target"]["resolvedReference"],
            "IT",
        )
        for turn in (knowledge, description, knowledge_follow_up):
            self.assert_no_effects(turn)

    def test_medical_pronouns_remain_truthful_when_health_is_unknown(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        for key in ("healthState", "bodyHealth", "hpCurrent", "hpMax"):
            scenario["npc"][key] = None

        with LuaSemanticWorker(scenario) as worker:
            direct = worker.input("are you hurt")
            follow_up = worker.input("does it still hurt")
            second_follow_up = worker.input("what about that")

        for turn in (direct, follow_up, second_follow_up):
            self.assertEqual(
                turn["result"]["ir"]["diagnostics"]["factStatus"], "unknown"
            )
            text = self.message_text(turn).lower()
            self.assertIn("can't confirm", text)
            self.assertNotIn("healthy", text)
            self.assertNotIn("not injured", text)
            self.assertEqual(
                turn["trace"][0]["data"]["classification"],
                "recognized_question_unknown_fact",
            )
            self.assert_no_effects(turn)

        target = follow_up["result"]["ir"]["target"]
        self.assertEqual(target["resolvedReference"], "IT")
        self.assertEqual(target["concept"], "NPC_HEALTH_STATE")
        self.assertEqual(
            follow_up["result"]["decision"]["response"]["selectionSource"],
            "conversation_reference",
        )

    def test_unresolved_reference_is_recognized_without_inventing_a_fact(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("what about it")

        self.assertTrue(turn["accepted"], turn.get("reason"))
        self.assertEqual(
            turn["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.context_reference.what_about_it",
        )
        self.assertTrue(turn["result"]["ir"]["target"]["unresolved"])
        self.assertEqual(
            turn["trace"][0]["data"]["classification"],
            "recognized_question_unknown_fact",
        )
        self.assertEqual(turn["result"]["decision"]["route"], "deterministic")
        self.assert_no_effects(turn)
        self.assertNotIn("npc.", self.message_text(turn).lower())

    def test_needs_commitment_survives_topic_switch_without_dispatch(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            needs = worker.input("do you need anything")
            quantity = worker.input("how many")
            promise = worker.input("i will get some")
            weather = worker.input("what is the weather")
            acknowledgement = worker.input("okay")

        self.assertEqual(
            needs["contextAfter"]["dialogue"]["pendingFollowUp"]["id"],
            "flow:needs:await_player_quantity",
        )
        self.assertEqual(
            quantity["result"]["ir"]["extensions"]["contextualFollowUp"][
                "status"
            ],
            "matched",
        )
        self.assertEqual(
            promise["contextAfter"]["dialogue"]["pendingFollowUp"]["id"],
            "flow:needs:proposal_pending",
        )
        self.assertEqual(
            weather["result"]["ir"]["extensions"]["contextualFollowUp"][
                "status"
            ],
            "interrupted",
        )
        self.assertEqual(
            weather["contextAfter"]["dialogue"]["pendingFollowUp"]["id"],
            "flow:needs:proposal_pending",
        )
        self.assertEqual(weather["result"].get("actionResult"), None)
        self.assertEqual(weather["transport"], [])
        self.assertEqual(
            acknowledgement["result"]["ir"]["extensions"]["contextualFollowUp"][
                "status"
            ],
            "matched",
        )
        self.assertEqual(
            acknowledgement["contextAfter"]["dialogue"]["pendingFollowUp"][
                "status"
            ],
            "open",
        )
        self.assertEqual(acknowledgement["result"].get("actionResult"), None)
        self.assertEqual(acknowledgement["transport"], [])

    def test_participant_context_isolation_and_preview_are_effect_free(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        with LuaSemanticWorker(scenario) as first:
            first.input("where is your home")
            first_reference = first.input("what about it")
            before = first.snapshot()
            preview = first.preview("is it safe there")
            after = first.snapshot()
            first.set_language("TL")
            tl_turn = first.input("is it safe there")

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as second:
            second_reference = second.input("what about it")

        self.assertIn("Riverside Camp", self.message_text(first_reference))
        self.assertTrue(second_reference["result"]["ir"]["target"]["unresolved"])
        self.assertNotIn("Riverside Camp", self.message_text(second_reference))
        self.assertEqual(
            {key: value for key, value in before.items() if key != "id"},
            {key: value for key, value in after.items() if key != "id"},
        )
        self.assertEqual(preview["messages"], [])
        self.assertEqual(preview["transport"], [])
        self.assertEqual(preview["toolCalls"], [])
        self.assertEqual(preview["llmCalls"], 0)
        self.assertEqual(
            tl_turn["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_ContextReferenceLocationSafetyUnknown",
        )
        self.assertIn("ligtas", self.message_text(tl_turn))
        self.assertEqual(tl_turn["transport"], [])
        self.assertEqual(tl_turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
