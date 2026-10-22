"""C7C conversational initiative probes on the real Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class ConversationalCompetenceC7CTests(unittest.TestCase):
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

    def test_continuation_paraphrases_follow_the_previous_topic(self) -> None:
        phrases = (
            "tell me more",
            "can you say more",
            "say more",
            "what else",
            "anything else",
            "go on",
            "keep going",
            "continue",
            "can you tell me more",
        )
        for phrase in phrases:
            with self.subTest(phrase=phrase):
                with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
                    news = worker.input("do you have any news")
                    turn = worker.input(phrase)
                self.assertEqual(news["result"]["ir"]["intent"], "GOSSIP")
                self.assert_no_effects(turn)
                ir = turn["result"]["ir"]
                self.assertEqual(ir["intent"], "QUESTION")
                self.assertEqual(ir["subject"], "CONVERSATION")
                self.assertEqual(
                    ir["extensions"]["dialogueFollowUp"],
                    "CONVERSATION_CONTINUATION",
                )
                self.assertTrue(
                    ir["provenance"]["pattern"].startswith(
                        "pnc.social.continuation."
                    )
                )
                self.assertEqual(
                    turn["result"]["decision"]["response"]["selectionSource"],
                    "conversation_context",
                )
                self.assertEqual(
                    turn["trace"][0]["data"]["classification"],
                    "recognized_question",
                )
                self.assertEqual(
                    turn["trace"][0]["data"]["responseClassification"],
                    "grounded_npc_response",
                )
                self.assertIn("anything else", self.message_text(turn).lower())
                self.assertEqual(
                    turn["contextAfter"]["dialogue"]["currentTopic"],
                    "gossip",
                )

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            negative = worker.preview("give me more food")
        negative_ir = negative["result"]["ir"]
        self.assertNotEqual(
            negative_ir.get("extensions", {}).get("dialogueFollowUp"),
            "CONVERSATION_CONTINUATION",
        )
        self.assertEqual(negative["transport"], [])
        self.assertEqual(negative["toolCalls"], [])

    def test_acknowledgements_preserve_context_without_authorizing_actions(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            relationship = worker.input("are you single")
            acknowledged = worker.input("okay")

        self.assertEqual(
            acknowledged["result"]["decision"]["response"]["templateID"],
            "semantic.question.relationship_status.acknowledged.alternate",
        )
        self.assertEqual(
            acknowledged["contextAfter"]["dialogue"]["currentTopic"],
            "RELATIONSHIP_STATUS",
        )
        self.assertIn("appreciate", self.message_text(acknowledged).lower())
        self.assert_no_effects(acknowledged)
        self.assertEqual(relationship["transport"], [])

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            question = worker.input("are you hurt")
            acknowledged = worker.input("okay")
            continuation = worker.input("tell me more")
            command = worker.input("wait here")
            command_ack = worker.input("okay")

        self.assertEqual(question["result"]["ir"]["subject"], "NPC_HEALTH_STATE")
        self.assertEqual(
            acknowledged["result"]["decision"]["response"]["templateID"],
            "semantic.conversation.acknowledged.default",
        )
        self.assertEqual(
            acknowledged["contextAfter"]["dialogue"]["currentTopic"],
            "medical",
        )
        self.assert_no_effects(acknowledged)
        self.assertEqual(
            continuation["result"]["decision"]["response"]["templateID"],
            "semantic.conversation.continuation.medical_known",
        )
        self.assertIn("anything more", self.message_text(continuation).lower())
        self.assert_no_effects(continuation)
        self.assertEqual(command["result"]["ir"]["action"], "STAY")
        self.assertTrue(command["result"]["actionResult"]["accepted"])
        self.assert_no_effects(command_ack)
        self.assertIsNone(command_ack["result"].get("actionResult"))

    def test_topic_carryover_and_truthful_unknown_continuation(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        scenario["npc"]["healthState"] = None
        scenario["npc"]["bodyHealth"] = None
        with LuaSemanticWorker(scenario) as worker:
            residence = worker.input("where is your home")
            health = worker.input("what about your health")
            continuation = worker.input("tell me more")

        self.assertEqual(residence["result"]["ir"]["subject"], "NPC_RESIDENCE")
        self.assertEqual(residence["result"]["ir"]["diagnostics"]["factStatus"], "known")
        self.assertEqual(health["result"]["ir"]["subject"], "NPC_HEALTH_STATE")
        self.assertEqual(health["result"]["ir"]["diagnostics"]["factStatus"], "unknown")
        self.assertIn("can't confirm", self.message_text(health).lower())
        self.assertEqual(continuation["result"]["ir"]["subject"], "CONVERSATION")
        self.assertEqual(
            continuation["result"]["decision"]["response"]["templateID"],
            "semantic.conversation.continuation.medical_unknown",
        )
        self.assertIn("can't confirm", self.message_text(continuation).lower())
        self.assert_no_effects(health)
        self.assert_no_effects(continuation)

    def test_preview_and_tl_continuation_are_effect_free_and_localized(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        with LuaSemanticWorker(scenario) as worker:
            worker.input("where do you live exactly")
            before = worker.snapshot()
            preview = worker.preview("tell me more")
            after = worker.snapshot()
            worker.set_language("TL")
            tl_turn = worker.input("tell me more")

        self.assertEqual(
            {key: value for key, value in before.items() if key != "id"},
            {key: value for key, value in after.items() if key != "id"},
        )
        self.assert_no_effects(preview)
        self.assertEqual(preview["messages"], [])
        self.assertEqual(
            preview["result"]["decision"]["response"]["templateID"],
            "semantic.conversation.continuation.residence",
        )
        self.assertEqual(tl_turn["translation"]["language"], "TL")
        self.assertEqual(
            tl_turn["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_ConversationContinuationResidence",
        )
        self.assertIn("tinitirhan", self.message_text(tl_turn))
        self.assert_no_effects(tl_turn)


if __name__ == "__main__":
    unittest.main()
