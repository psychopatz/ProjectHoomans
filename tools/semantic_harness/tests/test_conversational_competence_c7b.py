"""C7B grounded factual-question probes on the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ConversationalCompetenceC7BTests(unittest.TestCase):
    @staticmethod
    def message_text(turn: dict) -> str:
        payload = turn["messages"][-1]["payload"]
        if isinstance(payload, dict):
            return str(payload.get("text") or payload.get("fallback") or "")
        return str(payload or "")

    def assert_fact_question(self, turn: dict, subject: str) -> dict:
        self.assertTrue(turn["accepted"], turn.get("reason"))
        self.assertEqual(turn["result"]["decision"]["route"], "deterministic")
        self.assertEqual(turn["result"]["ir"]["subject"], subject)
        self.assertEqual(turn["result"].get("actionResult"), None)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(len(turn["messages"]), 1)
        self.assertEqual(
            turn["trace"][0]["data"]["classification"],
            "recognized_question_unknown_fact"
            if turn["result"]["ir"]["diagnostics"].get("factStatus")
            == "unknown"
            else "recognized_question",
        )
        return turn["result"]["ir"]["extensions"]["facts"][subject]

    @staticmethod
    def unknown_health_scenario() -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["healthState"] = None
        scenario["npc"]["bodyHealth"] = None
        scenario["npc"]["hpCurrent"] = None
        scenario["npc"]["hpMax"] = None
        return scenario

    def test_natural_question_variants_answer_unknown_truthfully(self) -> None:
        cases = (
            (
                "where do you live exactly",
                "NPC_RESIDENCE",
                "I don't have a confirmed home",
            ),
            (
                "where is your home",
                "NPC_RESIDENCE",
                "I don't have a confirmed home",
            ),
            (
                "are you hurt",
                "NPC_HEALTH_STATE",
                "I can't confirm my health status",
            ),
            (
                "how are your wounds",
                "NPC_HEALTH_STATE",
                "I can't confirm my health status",
            ),
            (
                "do you know about the radio tower",
                "NPC_KNOWLEDGE",
                "I don't have reliable information about the radio tower",
            ),
            (
                "have you heard of the radio tower",
                "NPC_KNOWLEDGE",
                "I don't have reliable information about the radio tower",
            ),
        )
        for text, subject, expected_text in cases:
            with self.subTest(text=text):
                with LuaSemanticWorker(self.unknown_health_scenario()) as worker:
                    turn = worker.input(text)
                fact = self.assert_fact_question(turn, subject)
                self.assertEqual(fact["status"], "unknown")
                self.assertIn(expected_text.lower(), self.message_text(turn).lower())
                self.assertEqual(
                    turn["result"]["decision"]["response"]["uncertainty"],
                    "unknown",
                )
                self.assertNotIn("npc.", self.message_text(turn).lower())

    def test_known_facts_use_authoritative_projection_and_final_text(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        scenario["npc"]["healthState"] = "injured"
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
            health = worker.input("are you hurt")
            knowledge = worker.input("do you know about the radio tower")

        residence_fact = residence["result"]["ir"]["extensions"]["facts"][
            "NPC_RESIDENCE"
        ]
        self.assertEqual(residence_fact["status"], "known")
        self.assertEqual(residence_fact["value"]["label"], "Riverside Camp")
        self.assertEqual(residence_fact["factRef"], "npc.residence")
        self.assertEqual(
            residence_fact["provenance"],
            "PNC.NPCResidence.authoritative_projection",
        )
        self.assertIn("Riverside Camp", self.message_text(residence))
        self.assertEqual(
            residence["result"]["decision"]["response"]["groundedFactRefs"],
            ["npc.residence"],
        )

        health_fact = health["result"]["ir"]["extensions"]["facts"][
            "NPC_HEALTH_STATE"
        ]
        self.assertEqual(health_fact["status"], "known")
        self.assertEqual(health_fact["value"], "injured")
        self.assertEqual(health_fact["factRef"], "npc.healthState")
        self.assertIn("hurt", self.message_text(health).lower())
        self.assertEqual(
            health["result"]["decision"]["response"]["groundedFactRefs"],
            ["npc.healthState"],
        )

        knowledge_fact = knowledge["result"]["ir"]["extensions"]["facts"][
            "NPC_KNOWLEDGE"
        ]
        self.assertEqual(knowledge_fact["status"], "known")
        self.assertTrue(knowledge_fact["value"])
        self.assertEqual(knowledge_fact["factRef"], "npc.knowledge.topic")
        self.assertEqual(
            knowledge_fact["provenance"],
            "PNC.NPCKnowledge.authoritative_projection",
        )
        self.assertIn("radio tower", self.message_text(knowledge).lower())
        self.assertIn("north of here", self.message_text(knowledge).lower())
        self.assertEqual(
            knowledge["result"]["decision"]["response"]["groundedFactRefs"],
            ["npc.knowledge.topic"],
        )

    def test_inventory_relationship_and_command_authority_are_preserved(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            inventory = worker.input("what do you have")
        self.assertEqual(inventory["result"]["ir"]["subject"], "INVENTORY")
        self.assertEqual(
            inventory["result"]["decision"]["branch"],
            "INVENTORY_QUERY_RECEIVED",
        )
        self.assertTrue(inventory["result"]["actionResult"]["accepted"])
        self.assertEqual(inventory["result"]["actionResult"]["status"], "found")
        self.assertGreaterEqual(len(inventory["transport"]), 1)

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            relationship = worker.input("are you single")
        self.assertEqual(
            relationship["result"]["ir"]["subject"],
            "RELATIONSHIP_STATUS",
        )
        self.assertEqual(relationship["transport"], [])
        self.assertEqual(relationship["toolCalls"], [])
        self.assertTrue(self.message_text(relationship))

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            stay = worker.input("wait here")
        self.assertEqual(stay["result"]["ir"]["action"], "STAY")
        self.assertEqual(stay["result"]["decision"]["branch"], "COMMAND_ACCEPTED")
        self.assertTrue(stay["result"]["actionResult"]["accepted"])
        self.assertEqual(len(stay["transport"]), 1)
        self.assertEqual(stay["result"]["actionResult"]["capabilityID"], "pnc:companion.stay")

    def test_social_and_gossip_inputs_do_not_become_factual_actions(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            gossip = worker.input("did you hear that someone got bitten")
            negative = worker.input("i don't like your dress")

        self.assertEqual(gossip["result"]["ir"]["intent"], "GOSSIP")
        self.assertEqual(gossip["result"]["ir"]["subject"], "GOSSIP")
        self.assertEqual(gossip["transport"], [])
        self.assertEqual(negative["result"]["ir"]["diagnostics"]["noMatch"], True)
        self.assertEqual(negative["trace"][0]["data"]["classification"], "unrecognized_language")
        self.assertEqual(negative["transport"], [])
        self.assertEqual(negative["toolCalls"], [])

    def test_tl_residence_translation_and_preview_are_effect_free(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        with LuaSemanticWorker(scenario) as worker:
            worker.input("hello")
            before = worker.snapshot()
            preview = worker.preview("where do you live exactly")
            after = worker.snapshot()
            worker.set_language("TL")
            tl_turn = worker.input("where do you live exactly")

        self.assertTrue(preview["accepted"], preview.get("reason"))
        self.assertEqual(preview["result"]["ir"]["subject"], "NPC_RESIDENCE")
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
            "UI_PNC_Conversation_Semantic_QuestionResidenceKnown",
        )
        self.assertIn("Nakatira ako sa Riverside Camp", self.message_text(tl_turn))
        self.assertEqual(tl_turn["transport"], [])
        self.assertEqual(tl_turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
