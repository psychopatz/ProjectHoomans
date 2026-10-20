"""B0 real-worker regression for social apparel evaluations vs inventory queries."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class GroundedPersonalDialogueB0Tests(unittest.TestCase):
    @staticmethod
    def response_text(turn: dict) -> str:
        payload = turn["messages"][-1]["payload"]
        if isinstance(payload, dict):
            return str(payload.get("text") or payload.get("fallback") or "")
        return str(payload or "")

    def run_turn(self, text: str, language: str = "EN") -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            if language != "EN":
                worker.set_language(language)
            return worker.input(text)

    def assert_social_compliment(self, text: str, pattern: str) -> dict:
        turn = self.run_turn(text)
        self.assertTrue(turn["accepted"], turn.get("reason"))
        ir = turn["result"]["ir"]
        self.assertEqual(ir["intent"], "COMPLIMENT")
        self.assertEqual(ir["speechAct"], "COMPLIMENT")
        self.assertEqual(ir["provenance"]["pattern"], pattern)
        self.assertEqual(turn["result"]["decision"]["branch"],
                         "COMPLIMENT_RECEIVED")
        self.assertIsNone(turn["result"].get("actionResult"))
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertEqual(turn["llmCalls"], 0)
        response = self.response_text(turn).lower()
        self.assertIn("thank", response)
        self.assertNotIn("have any", response)
        return turn

    def assert_inventory_query(self, text: str) -> dict:
        turn = self.run_turn(text)
        self.assertTrue(turn["accepted"], turn.get("reason"))
        ir = turn["result"]["ir"]
        self.assertEqual(ir["intent"], "QUESTION")
        self.assertEqual(ir["subject"], "INVENTORY")
        self.assertEqual(ir["provenance"]["pattern"],
                         "pnc.question.inventory_you_got"
                         if text.lower().startswith("you got")
                         else "pnc.question.inventory_have_you_got")
        self.assertEqual(turn["result"]["decision"]["branch"],
                         "INVENTORY_QUERY_RECEIVED")
        self.assertEqual(turn["result"]["decision"]["route"], "deterministic")
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(
            [entry["command"] for entry in turn["transport"]],
            ["SemanticInventoryQuery", "SemanticInventoryQueryResult"],
        )
        self.assertEqual(turn["result"]["actionResult"]["status"], "empty")
        self.assertIn("don't have any", self.response_text(turn).lower())
        return turn

    def test_compositional_apparel_compliments_do_not_query_inventory(self) -> None:
        self.assert_social_compliment(
            "nice dress",
            "pnc.social.compliment_adjective_feature",
        )

        colloquial = self.assert_social_compliment(
            "you got nice dress",
            "pnc.social.compliment_you_got_feature",
        )
        candidates = colloquial["result"]["candidates"]["candidates"]
        self.assertGreaterEqual(len(candidates), 2)
        self.assertEqual(
            candidates[0]["patternID"],
            "pnc.social.compliment_you_got_feature",
        )
        self.assertTrue(any(
            candidate["patternID"] == "pnc.question.inventory_you_got"
            and candidate.get("selected", False) is False
            for candidate in candidates
        ))

        self.assert_social_compliment(
            "you got a nice dress",
            "pnc.social.compliment_you_got_feature_a",
        )

    def test_inventory_cues_still_win_for_actual_questions(self) -> None:
        self.assert_inventory_query("have you got a dress?")
        self.assert_inventory_query("you got any bandages?")
        self.assert_inventory_query("you got a dress")

    def test_negation_and_third_party_language_fail_closed(self) -> None:
        for text in ("you don't got a dress", "John said you got a dress"):
            with self.subTest(text=text):
                turn = self.run_turn(text)
                self.assertTrue(turn["accepted"], turn.get("reason"))
                self.assertTrue(turn["result"]["ir"]["diagnostics"]["noMatch"])
                self.assertEqual(turn["result"]["decision"]["branch"],
                                 "ASK_CLARIFICATION")
                self.assertIsNone(turn["result"].get("actionResult"))
                self.assertEqual(turn["transport"], [])
                self.assertEqual(self.response_text(turn),
                                 "I'm not sure what you mean.")

    def test_en_tl_use_the_same_semantic_boundary(self) -> None:
        social = self.assert_social_compliment(
            "you got a nice dress",
            "pnc.social.compliment_you_got_feature_a",
        )
        self.assertEqual(social["translation"]["language"], "EN")

        tl = self.run_turn("you got a nice dress", language="TL")
        self.assertEqual(tl["result"]["ir"]["intent"], "COMPLIMENT")
        self.assertEqual(tl["result"]["ir"]["provenance"]["pattern"],
                         "pnc.social.compliment_you_got_feature_a")
        self.assertEqual(tl["translation"]["language"], "TL")
        self.assertTrue(self.response_text(tl))
        self.assertEqual(tl["transport"], [])
        self.assertEqual(tl["result"].get("actionResult"), None)

        inventory = self.run_turn("you got any bandages?", language="TL")
        self.assertEqual(inventory["result"]["ir"]["subject"], "INVENTORY")
        self.assertEqual(
            [entry["command"] for entry in inventory["transport"]],
            ["SemanticInventoryQuery", "SemanticInventoryQueryResult"],
        )

    def test_seed_backstory_reconstructs_across_language_and_worker_reload(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.backstory(90210, "colonist", "npc-backstory-b0")
            worker.set_language("TL")
            localized = worker.backstory(90210, "colonist", "npc-backstory-b0")
            worker.restart()
            reloaded = worker.backstory(90210, "colonist", "npc-backstory-b0")

        self.assertTrue(first["ok"])
        self.assertEqual(first["profile"], localized["profile"])
        self.assertEqual(first["profile"], reloaded["profile"])
        self.assertEqual(first["profile"]["identitySeed"], 90210)
        self.assertEqual(first["profile"]["tacticalClass"], "colonist")
        self.assertIn("former_job", first["profile"]["facts"])
        self.assertIn("hometown", first["profile"]["facts"])


if __name__ == "__main__":
    unittest.main()
