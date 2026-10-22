"""C7A conversational competence probes on the real Lua worker.

These tests exercise the production Project Hoomans semantic catalog, fact
resolver, response catalog, translation adapter, and lifecycle. They do not
replace native Project Zomboid live testing.
"""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ConversationalCompetenceC7ATests(unittest.TestCase):
    @staticmethod
    def message_text(turn: dict) -> str:
        payload = turn["messages"][-1]["payload"]
        if isinstance(payload, dict):
            return str(payload.get("text") or payload.get("fallback") or "")
        return str(payload or "")

    def assert_offline_question(self, turn: dict) -> None:
        self.assertTrue(turn["accepted"], turn.get("reason"))
        self.assertEqual(turn["result"]["decision"]["route"], "deterministic")
        self.assertEqual(turn["result"].get("actionResult"), None)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["relationshipBefore"], turn["relationshipAfter"])
        self.assertEqual(len(turn["messages"]), 1)

    def test_required_five_turn_semantic_lab_sequence(self) -> None:
        inputs = (
            "do you have any news",
            "wait here",
            "where do you live exactly",
            "have you been bitten",
            "i like your dress",
        )
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turns = [worker.input(value) for value in inputs]

        news, stay, residence, bite, compliment = turns
        self.assertEqual(
            news["result"]["ir"]["provenance"]["pattern"],
            "pnc.social.news_do_you_have",
        )
        self.assertEqual(news["result"]["decision"]["branch"], "GOSSIP_RECEIVED")
        self.assertEqual(news["trace"][0]["data"]["classification"], "recognized_social_interaction")

        self.assertEqual(stay["result"]["ir"]["provenance"]["pattern"], "pnc.command.wait")
        self.assertEqual(stay["result"]["ir"]["action"], "STAY")
        self.assertEqual(stay["result"]["decision"]["branch"], "COMMAND_ACCEPTED")
        self.assertTrue(stay["result"]["actionResult"]["accepted"])
        self.assertEqual(stay["trace"][0]["data"]["classification"], "authorized_gameplay_action")

        self.assertEqual(residence["result"]["ir"]["subject"], "NPC_RESIDENCE")
        self.assertEqual(
            residence["result"]["ir"]["diagnostics"]["factStatus"],
            "unknown",
        )
        self.assertEqual(
            residence["result"]["decision"]["branch"],
            "QUESTION_RECEIVED",
        )
        self.assertEqual(
            residence["trace"][0]["data"]["classification"],
            "recognized_question_unknown_fact",
        )
        self.assertEqual(residence["transport"], [])

        self.assertEqual(bite["result"]["ir"]["subject"], "NPC_BITE_STATUS")
        self.assertEqual(bite["result"]["ir"]["diagnostics"]["factStatus"], "unknown")
        self.assertEqual(bite["result"]["decision"]["response"]["uncertainty"], "unknown")
        self.assertIn("can't confirm", self.message_text(bite).lower())
        self.assertEqual(
            bite["trace"][0]["data"]["classification"],
            "recognized_question_unknown_fact",
        )
        self.assertEqual(bite["trace"][0]["data"]["responseClassification"], "grounded_npc_response")
        self.assertEqual(bite["transport"], [])
        self.assertEqual(bite["toolCalls"], [])

        self.assertEqual(compliment["result"]["ir"]["intent"], "COMPLIMENT")
        self.assertEqual(compliment["result"]["decision"]["branch"], "COMPLIMENT_RECEIVED")
        self.assertEqual(
            compliment["result"]["ir"]["provenance"]["pattern"],
            "pnc.social.compliment_i_like_your_feature",
        )
        self.assertTrue(self.message_text(compliment))
        self.assertEqual(
            compliment["trace"][0]["data"]["classification"],
            "recognized_social_interaction",
        )
        self.assertEqual(compliment["transport"], [])
        self.assertEqual(compliment["toolCalls"], [])
        self.assertEqual(compliment["llmCalls"], 0)

    def test_apparel_compliment_categories_and_negative_holdout(self) -> None:
        positive = (
            ("i like your dress", "pnc.social.compliment_i_like_your_feature"),
            ("i really like your jacket", "pnc.social.compliment_i_really_like_your_feature"),
            ("you have a nice outfit", "pnc.social.compliment_you_have_feature_a"),
            ("your appearance looks beautiful", "pnc.social.compliment_your_looks_feature"),
        )
        for text, expected_pattern in positive:
            with self.subTest(text=text):
                with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
                    turn = worker.input(text)
                self.assertTrue(turn["accepted"], turn.get("reason"))
                ir = turn["result"]["ir"]
                self.assertEqual(ir["intent"], "COMPLIMENT")
                self.assertEqual(ir["provenance"]["pattern"], expected_pattern)
                self.assertEqual(turn["result"]["decision"]["branch"], "COMPLIMENT_RECEIVED")
                self.assertTrue(turn["result"]["decision"]["response"]["sourcePoolID"], turn)
                self.assertTrue(self.message_text(turn))
                self.assert_offline_question(turn)

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            negative = worker.input("i don't like your dress")
        self.assertEqual(negative["result"]["ir"]["diagnostics"]["noMatch"], True)
        self.assertEqual(negative["result"]["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertEqual(negative["trace"][0]["data"]["classification"], "unrecognized_language")
        self.assertIsNone(negative["result"].get("actionResult"))
        self.assertEqual(negative["transport"], [])
        self.assertEqual(negative["toolCalls"], [])

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            gossip = worker.input("did you hear that someone got bitten")
        self.assertEqual(gossip["result"]["ir"]["intent"], "GOSSIP")
        self.assertEqual(gossip["result"]["ir"]["subject"], "GOSSIP")
        self.assertEqual(gossip["result"]["ir"]["provenance"]["pattern"], "pnc.social.gossip_event")
        self.assertNotEqual(gossip["result"]["ir"]["subject"], "NPC_BITE_STATUS")
        self.assertEqual(gossip["transport"], [])

    def test_bite_status_uses_authoritative_projection_or_stays_unknown(self) -> None:
        cases = (
            (
                "known_positive",
                {"wounds": {"Head": {"type": "bite"}}},
                True,
                "semantic.question.medical_bite.positive",
                "bitten",
            ),
            (
                "known_negative",
                {"wounds": {}},
                False,
                "semantic.question.medical_bite.negative",
                "bite",
            ),
            (
                "unknown_missing_snapshot",
                None,
                None,
                "semantic.question.medical_bite.unknown",
                "confirm",
            ),
            (
                "unknown_partial_snapshot",
                {},
                None,
                "semantic.question.medical_bite.unknown",
                "confirm",
            ),
        )
        for label, body_health, value, template, expected_text in cases:
            with self.subTest(case=label):
                scenario = deepcopy(DEFAULT_SCENARIO)
                if body_health is not None:
                    scenario["npc"]["bodyHealth"] = body_health
                with LuaSemanticWorker(scenario) as worker:
                    turn = worker.input("did a zombie bite you")
                self.assert_offline_question(turn)
                fact = turn["result"]["ir"]["extensions"]["facts"]["NPC_BITE_STATUS"]
                response = turn["result"]["decision"]["response"]
                self.assertEqual(fact.get("status"), "known" if value is not None else "unknown")
                if value is not None:
                    self.assertEqual(fact.get("value"), value)
                    self.assertEqual(fact.get("provider"), "client_npc_health_projection")
                    self.assertEqual(fact.get("provenance"), "PNC.NPCWounds.BuildSnapshot")
                    self.assertEqual(response["groundedFactRefs"], ["npc.health.body.wounds"])
                    self.assertEqual(response["uncertainty"], "known")
                else:
                    self.assertNotIn("value", fact)
                    self.assertEqual(response["groundedFactRefs"], [])
                    self.assertEqual(response["uncertainty"], "unknown")
                self.assertEqual(response["templateID"], template)
                self.assertIn(expected_text.lower(), self.message_text(turn).lower())
                self.assertEqual(
                    turn["trace"][0]["data"]["responsePlan"]["uncertainty"],
                    "known" if value is not None else "unknown",
                )

    def test_preview_and_tl_response_are_effect_free_and_localized(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            # Initialize the ordinary conversation lease first. Preview must
            # then leave the live semantic/gameplay state byte-for-byte
            # unchanged while still using the production router and facts.
            worker.input("hello")
            before = worker.snapshot()
            preview = worker.preview("have you been bitten")
            after = worker.snapshot()
            worker.set_language("TL")
            tl_turn = worker.input("i like your dress")
            tl_bite = worker.input("have you been bitten")

        self.assertTrue(preview["accepted"], preview.get("reason"))
        self.assertEqual(preview["result"]["ir"]["subject"], "NPC_BITE_STATUS")
        self.assertEqual(preview["messages"], [])
        self.assertEqual(preview["transport"], [])
        self.assertEqual(preview["toolCalls"], [])
        self.assertEqual(preview["llmCalls"], 0)
        self.assertEqual(
            {key: value for key, value in before.items() if key != "id"},
            {key: value for key, value in after.items() if key != "id"},
        )

        self.assertEqual(tl_turn["translation"]["language"], "TL")
        self.assertEqual(
            tl_turn["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_ComplimentAlternate",
        )
        self.assertIn("Pinahahalagahan", self.message_text(tl_turn))
        self.assertEqual(tl_turn["transport"], [])
        self.assertEqual(tl_turn["toolCalls"], [])
        self.assertEqual(
            tl_bite["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteUnknown",
        )
        self.assertIn("makumpirma", self.message_text(tl_bite))
        self.assertEqual(tl_bite["transport"], [])
        self.assertEqual(tl_bite["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
