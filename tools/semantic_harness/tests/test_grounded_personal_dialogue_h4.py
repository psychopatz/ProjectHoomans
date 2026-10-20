"""H4 sparse persistence and optional-context acceptance checks."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class GroundedPersonalDialogueH4Tests(unittest.TestCase):
    @staticmethod
    def scenario(character_uuid: str = "char-h4-a") -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "player": {"characterUUID": character_uuid},
                "npc": {
                    "npcID": "npc-h4-grounded",
                    "identitySeed": 90210,
                    "identity": {"seed": 90210},
                    "tacticalClass": "colonist",
                    "relationship": {"familiarity": 80},
                },
            },
        )

    def test_moddata_measurement_is_sparse_and_scales_from_real_knowledge(self) -> None:
        with LuaSemanticWorker(self.scenario()) as worker:
            empty = worker.knowledge_metrics()
        with LuaSemanticWorker(self.scenario()) as worker:
            worker.input("what was your old job")
            one_fact = worker.knowledge_metrics()
        with LuaSemanticWorker(self.scenario()) as worker:
            scaled = worker.knowledge_metrics(100, 2)

        self.assertEqual(empty["serializedBytes"], 0)
        self.assertFalse(empty["persisted"])
        self.assertEqual(one_fact["npcCount"], 1)
        self.assertEqual(one_fact["evidenceCount"], 1)
        self.assertGreater(one_fact["serializedBytes"], empty["serializedBytes"])
        self.assertEqual(scaled["npcCount"], 100)
        self.assertEqual(scaled["evidenceCount"], 200)
        self.assertEqual(scaled["syntheticEvidenceRecorded"], 200)
        self.assertGreater(scaled["serializedBytes"], one_fact["serializedBytes"])

    def test_optional_pbrainz_context_receives_only_player_filtered_facts(self) -> None:
        with LuaSemanticWorker(self.scenario("char-h4-a")) as worker:
            disclosed = worker.input("what was your old job")
            pbrainz = disclosed["contextAfter"]["pbrainz"]
            self.assertTrue(pbrainz["disclosureFiltered"])
            self.assertEqual(pbrainz["backstoryFacts"][0]["content"], "farmer")
            self.assertTrue(pbrainz["backstoryFacts"][0]["authorized"])

            player_b = self.scenario("char-h4-b")
            worker.configure(player_b)
            worker.knowledge_bootstrap("h4-player-b-bootstrap")
            b_context = worker.snapshot()["context"]["pbrainz"]

        self.assertTrue(b_context["disclosureFiltered"])
        self.assertIsNone(b_context.get("backstoryFacts"))


if __name__ == "__main__":
    unittest.main()
