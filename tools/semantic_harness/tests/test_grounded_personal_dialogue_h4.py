"""H4 sparse persistence and optional-context acceptance checks."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


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
        self.assertGreater(empty["actorStorageBytes"], 0)
        self.assertEqual(empty["backstoryMetadataBytes"], 0)
        self.assertEqual(empty["knowledgeStorageBytes"], 0)
        self.assertGreater(empty["combinedStorageBytes"], empty["actorStorageBytes"])
        self.assertFalse(empty["persisted"])
        self.assertEqual(one_fact["npcCount"], 1)
        self.assertEqual(one_fact["evidenceCount"], 1)
        self.assertGreater(one_fact["serializedBytes"], empty["serializedBytes"])
        self.assertGreater(one_fact["backstoryMetadataBytes"], 0)
        self.assertGreater(one_fact["knowledgeStorageBytes"], 0)
        self.assertGreater(one_fact["combinedStorageBytes"], one_fact["actorStorageBytes"])
        self.assertEqual(scaled["npcCount"], 100)
        self.assertEqual(scaled["evidenceCount"], 200)
        self.assertEqual(scaled["syntheticEvidenceRecorded"], 200)
        self.assertGreater(scaled["serializedBytes"], one_fact["serializedBytes"])

    def test_ten_legitimate_discoveries_and_population_bounds_are_measured(self) -> None:
        topics = (
            "backstory.former_job",
            "backstory.hometown",
            "backstory.education",
            "backstory.hobby",
            "backstory.family_background",
            "backstory.value",
            "backstory.survival_origin",
            "backstory.fear",
            "backstory.tragedy",
            "backstory.date_of_birth",
        )
        with LuaSemanticWorker(self.scenario()) as worker:
            for topic in topics:
                result = worker.knowledge_discover(topic)
                self.assertTrue(result["ok"], (topic, result))
            ten_facts = worker.knowledge_metrics()
        with LuaSemanticWorker(self.scenario()) as worker:
            hundred = worker.knowledge_metrics(100, 1)
        with LuaSemanticWorker(self.scenario()) as worker:
            thousand = worker.knowledge_metrics(1000, 1)

        self.assertEqual(ten_facts["npcCount"], 1)
        self.assertEqual(ten_facts["evidenceCount"], 10)
        self.assertGreater(ten_facts["knowledgeStorageBytes"], 0)
        self.assertEqual(hundred["npcCount"], 100)
        self.assertEqual(hundred["evidenceCount"], 100)
        self.assertEqual(thousand["npcCount"], 1000)
        self.assertEqual(thousand["evidenceCount"], 1000)
        self.assertGreater(
            thousand["knowledgeStorageBytes"], hundred["knowledgeStorageBytes"]
        )

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
